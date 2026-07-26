# Rogers VoLTE Fix

A KernelSU module that enables VoLTE for Rogers (MCC 302/MNC 720) on ArrowOS/AOSP ROMs.

## Problem

Rogers does not enable VoLTE by default on AOSP-based ROMs. Without VoLTE, calls fall back to 3G/2G and WiFi calling doesn't work.

## What it does

Patches the carrier config XML to enable VoLTE for Rogers:
- `carrier_volte_available_bool` = true
- `carrier_volte_provisioning_required_bool` = false
- `carrier_ims_gba_required_bool` = false

## Safety: Slot-aware patching

On dual-SIM devices, patching carrier config for an empty SIM slot causes the Qualcomm RIL daemon to poll IMS on that slot. This triggers a known serial cross-talk bug (`Unexpected response`) between RIL[0] and RIL[1], causing network drops.

This module checks `gsm.sim.state` before patching:
- **Slot 1 empty**: Skips patching entirely (no cross-talk)
- **Slot 1 has SIM**: Patches both slots (both get VoLTE)

No manual configuration needed — it adapts automatically when you add/remove a SIM.

## Installation

1. Download the latest `fix_rogers_volte-v1.1.zip` from [Releases](../../releases)
2. Open KernelSU app → Modules → Install from storage
3. Select the zip file
4. Reboot

## Compatibility

- **ROM**: ArrowOS 13.1, AOSP-based ROMs (Android 13+)
- **Device**: Poco F3 (alioth) tested, should work on any Qualcomm dual-SIM device on Rogers
- **KernelSU**: 4.1.0+

## Changelog

### v1.1 (2026-07-26)
- Added slot-aware patching — skips when slot 1 is empty to prevent RIL cross-talk
- Moved carrier config patching from `post-fs-data.sh` to `service.sh` (SIM state available after boot)
- Added UICC slot state fallback for early boot detection

### v1.0 (2026-07-05)
- Initial release — patches carrier config to enable VoLTE

## Technical details

The module modifies `/data/user_de/0/com.android.phone/files/carrierconfig-*.xml` at boot. The patch is idempotent — it checks if VoLTE is already enabled before writing.

## License

MIT
