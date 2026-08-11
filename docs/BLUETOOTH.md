# Bluetooth

USB and Bluetooth identities are associated only through combined evidence:
an exact product alias, usage page/usage, vendor and VID, an initial USB
fingerprint, one user confirmation, and a persistent local alias. A Bluetooth
device without a serial number is never identified by its name alone.

The source system had paired `Air75 V3-2` (system_profiler vendor ID
`0x07D7`, 100% battery at inspection time) but it was not connected. Complete
acceptance still requires unplugging USB, selecting the appropriate hardware
mode, and connecting Bluetooth. Record the Bluetooth HID VID/PID, interfaces,
knob events, native and learned F1-F12 usages, sleep/wake behavior, and
duplicate-device behavior. The keyboard’s onboard effects continue to run in
firmware, but live lighting changes must return to USB-C or the verified U1
route.

Live Bluetooth lighting and keymap management are **REQUIRES HARDWARE
VERIFICATION**; the current implementation intentionally exposes Bluetooth
only as an input path.
