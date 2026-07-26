#!/system/bin/sh
# Resilient, session-timestamped modem logger + watchdog for Poco F3 (alioth).
# Each launch writes a NEW timestamped file so historical drops are never
# rotated away by logcat's -n count. Self-healing: respawns logcat if it dies.
# WATCHDOG: monitors radio buffer for drop patterns, saves snapshots.
# STATS: persistent CSV of signal/registration state every 10s (survives logcat rotation).

TS=$(date +%Y%m%d_%H%M%S)
LOG=/sdcard/modem_watch_${TS}.txt
SNAP_DIR=/sdcard/modem_snapshots
STATS=/sdcard/modem_stats_history.csv
mkdir -p "$SNAP_DIR"
echo "modem_logger session start $(date) -> $LOG" >> /sdcard/modem_watch_sessions.log

# Initialize stats CSV with header if missing
if [ ! -f "$STATS" ]; then
  echo "timestamp,slot0_voice,slot0_data,slot0_operator,slot0_rat,slot0_rsrp,slot0_level,slot1_voice,slot1_data,slot1_operator,slot1_rat" > "$STATS"
fi

# Increase radio buffer to 16MB for longer retention
logcat -b radio -G 16M 2>/dev/null

# Stats collector: append signal/registration state every 10s
stats_collector() {
  while true; do
    sleep 10
    TS_NOW=$(date '+%Y-%m-%d %H:%M:%S')
    # Parse telephony registry for both slots
    REG=$(dumpsys telephony.registry 2>/dev/null | grep -E 'mServiceState=' | head -2)
    S0_V=$(echo "$REG" | head -1 | grep -o 'mVoiceRegState=[^,]*' | head -1 | cut -d= -f2)
    S0_D=$(echo "$REG" | head -1 | grep -o 'mDataRegState=[^,]*' | head -1 | cut -d= -f2)
    S0_OP=$(echo "$REG" | head -1 | grep -o 'mOperatorAlphaLong=[^,]*' | head -1 | cut -d= -f2)
    S0_RAT=$(echo "$REG" | head -1 | grep -o 'getRilDataRadioTechnology=[^,]*' | head -1 | cut -d= -f2)
    S1_V=$(echo "$REG" | tail -1 | grep -o 'mVoiceRegState=[^,]*' | head -1 | cut -d= -f2)
    S1_D=$(echo "$REG" | tail -1 | grep -o 'mDataRegState=[^,]*' | head -1 | cut -d= -f2)
    S1_OP=$(echo "$REG" | tail -1 | grep -o 'mOperatorAlphaLong=[^,]*' | head -1 | cut -d= -f2)
    S1_RAT=$(echo "$REG" | tail -1 | grep -o 'getRilDataRadioTechnology=[^,]*' | head -1 | cut -d= -f2)
    # Parse signal strength for slot 0
    SIG=$(dumpsys telephony.registry 2>/dev/null | grep 'mSignalStrength=' | head -1)
    S0_RSRP=$(echo "$SIG" | grep -o 'rsrp=[0-9-]*' | head -1 | cut -d= -f2)
    S0_LVL=$(echo "$SIG" | grep -o 'level=[0-9]*' | head -1 | cut -d= -f2)
    echo "$TS_NOW,$S0_V,$S0_D,$S0_OP,$S0_RAT,$S0_RSRP,$S0_LVL,$S1_V,$S1_D,$S1_OP,$S1_RAT" >> "$STATS"
  done
}

# Watchdog: poll radio buffer for drop patterns, save snapshot on match
watchdog() {
  LAST_SNAP=0
  while true; do
    sleep 10
    # Cooldown: at most one snapshot per 60 seconds
    NOW=$(date +%s)
    [ $((NOW - LAST_SNAP)) -lt 60 ] && continue

    # Check for any drop pattern in the last 200 lines of radio buffer
    MATCH=$(logcat -b radio -d -v threadtime -t 200 2>/dev/null | grep -c \
      -e 'Unexpected response' \
      -e 'radioState=1' \
      -e 'OUT_OF_SERVICE' \
      -e 'EMERGENCY_ONLY' \
      -e 'SIGNAL_LOST' \
      -e 'nas_srv_status.*0' \
      -e 'modem.*crash' \
      -e 'ssr' \
      -e 'subsys_restart' \
      2>/dev/null)

    if [ "$MATCH" -gt 0 ]; then
      SNAP_TS=$(date +%Y%m%d_%H%M%S)
      SNAP_FILE="$SNAP_DIR/modem_drop_${SNAP_TS}.txt"
      {
        echo "=== DEVICE STATE $(date) ==="
        echo "--- props ---"
        getprop gsm.operator.alpha
        getprop gsm.network.type
        getprop persist.radio.airplane_mode_on
        echo "--- telephony ---"
        dumpsys telephony.registry 2>/dev/null | grep -E 'mCallState|mServiceState|mSignalStrength' | head -12
        echo "--- radio buffer (last 1500 lines) ---"
        logcat -b radio -d -v threadtime -t 1500 2>/dev/null
      } > "$SNAP_FILE" 2>&1
      echo "modem_drop_captured $SNAP_TS matches=$MATCH -> $SNAP_FILE" >> /sdcard/modem_watch_sessions.log
      LAST_SNAP=$NOW
    fi
  done
}

# Start background daemons
stats_collector &
watchdog &

# Main logger loop
while true; do
  logcat -b radio -b kernel -b system -v threadtime -f "$LOG" -r 4096 -n 20 >/dev/null 2>&1
  # logcat exited (error/edge); brief backoff then respawn
  sleep 3
done
