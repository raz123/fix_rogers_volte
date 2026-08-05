# Rogers VoLTE Fix

KernelSU module for Rogers (MCC 302/MNC 720) on AOSP ROMs.

## What it does

- **Enables VoLTE** — patches the carrier config XML with slot-aware safety: skips patching when the slot-1 SIM isn't active, preventing RIL cross-talk on Qualcomm dual-SIM devices.

## Root cause

AOSP ROMs ship without a Rogers carrier config that enables VoLTE, so the IMS stack stays off even though the modem supports it. This module patches the device's carrier config to flip VoLTE on, with `carrier_volte_provisioning_required_bool=false` and `carrier_ims_gba_required_bool=false` so registration succeeds without carrier provisioning or GBA.

Band control (LTE/NR band selection — e.g. avoiding the SM8250's crash-prone 66↔7 handover) is handled by the companion [Band Controller](https://github.com/raz123/bandctl) module.

## Installation

1. Download the latest `fix_rogers_volte-*.zip` from [Releases](../../releases)
2. KernelSU app → Modules → Install from storage
3. Reboot

## Compatibility

- **Device:** Poco F3 (alioth) and other SM8250 devices on North American carriers
- **ROM:** ArrowOS 13.1, AOSP-based ROMs (Android 13+)
- **KernelSU:** 4.1.0+

## Changelog

### v1.1
- Slot-aware patching — skips when slot 1 is empty

### v1.0
- Initial release

## License

MIT
