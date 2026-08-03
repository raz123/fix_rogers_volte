# Rogers VoLTE Fix

KernelSU module for Rogers (MCC 302/MNC 720) on AOSP ROMs.

## What it does

1. **Enables VoLTE** — patches carrier config XML with slot-aware safety
2. **Forces LTE-only mode** — disables 5G to prevent SM8250 modem crash on North American networks

## Root cause

The Qualcomm SM8250 modem has a known bug: it crashes during 5G/4G handover on North American carriers (Rogers, T-Mobile). AOSP kernels patch this as SSR (subsystem restart, 10-30s outage) instead of a full reboot. MIUI has workarounds; AOSP doesn't.

**The fix:** Force LTE-only mode (`preferred_network_mode=9,9`) and disable NR dual connectivity (`persist.vendor.radio.force_nr_dc=0`) via `resetprop`.

## Installation

1. Download `fix_rogers_volte-v1.2.zip` from [Releases](../../releases)
2. KernelSU app → Modules → Install from storage
3. Reboot

## Compatibility

- **Device:** Poco F3 (alioth) and other SM8250 devices on North American carriers
- **ROM:** ArrowOS 13.1, AOSP-based ROMs (Android 13+)
- **KernelSU:** 4.1.0+

## Changelog

### v1.2
- Add persistent LTE-only mode (disable 5G) to prevent SM8250 modem crash
- Use `resetprop` for `persist.vendor.radio.force_nr_dc=0` (set before `preferred_network_mode`)

### v1.1
- Slot-aware patching — skips when slot 1 is empty

### v1.0
- Initial release

## License

MIT
