#!/system/bin/sh
# Rogers VoLTE carrier config fix (service.sh - runs after boot_completed)
# Patches carrier config XML to enable VoLTE for Rogers (MCC 302/MNC 720)
#
# SAFETY: Only patches if slot 1 has a SIM — prevents RIL[1] IMS polling
# on empty slots which causes "Unexpected response" serial cross-talk
# between RIL[0] and RIL[1] on Qualcomm dual-SIM devices.

CC_DIR=/data/user_de/0/com.android.phone/files

# Wait for SIM state to be available (modem init takes time)
i=0
while [ "$(getprop gsm.sim.state)" = "" ] && [ "$i" -lt 20 ]; do
  sleep 2
  i=$((i+1))
done

# Check slot 1 SIM state
SIM_STATES=$(getprop gsm.sim.state)
SLOT1_STATE=$(echo "$SIM_STATES" | cut -d, -f2)

# Fallback: check UICC slot state if gsm.sim.state is still empty
if [ -z "$SLOT1_STATE" ]; then
  SLOT1_PRESENT=$(dumpsys phone 2>/dev/null | grep -i 'UiccSlot.*1' | grep -ci 'present\|active')
  if [ "$SLOT1_PRESENT" = "0" ]; then
    exit 0
  fi
fi

# Skip if slot 1 is empty
if [ "$SLOT1_STATE" != "LOADED" ] && [ "$SLOT1_STATE" != "READY" ]; then
  exit 0
fi

# Slot 1 has a SIM — safe to patch
for f in $CC_DIR/carrierconfig-*.xml; do
  [ -f "$f" ] || continue
  grep -q 'carrier_volte_available_bool" value="true"' "$f" 2>/dev/null && continue
  grep -q '</bundle>' "$f" || continue
  sed -i 's|</bundle>|<boolean name="carrier_volte_available_bool" value="true" />\n<boolean name="carrier_volte_provisioning_required_bool" value="false" />\n<boolean name="carrier_ims_gba_required_bool" value="false" />\n</bundle>|' "$f"
done
