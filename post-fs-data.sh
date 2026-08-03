#!/system/bin/sh
# Rogers VoLTE carrier config fix
# post-fs-data.sh — carrier config patching moved to service.sh
# (SIM state is not available this early, so we skip patching here)
# Actual patching with SIM slot awareness happens in service.sh.
