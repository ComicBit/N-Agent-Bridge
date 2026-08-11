# Air75HIDInspector

The source is `Sources/Air75HIDInspector/main.swift` and reuses Core’s
verified device matching.

```sh
swift run --disable-sandbox Air75HIDInspector
swift run --disable-sandbox Air75HIDInspector --listen 30
```

The second command read-only prints HID usages from recognized Air75 V3
interfaces for physical calibration during the selected 30-second window.
