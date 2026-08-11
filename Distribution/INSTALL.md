# N Agent Bridge installation

This development build supports the NuPhy Air75 V3 ANSI on macOS 13 or
later. It is not Apple Developer ID notarized.

1. Drag **N Agent Bridge.app** into **Applications**.
2. If Gatekeeper blocks the first launch, open **System Settings → Privacy &
   Security** and choose **Open Anyway** for this known-source build. Do not
   disable Gatekeeper globally.
3. Grant **Input Monitoring** and **Accessibility** to N Agent Bridge, then
   quit and reopen it.
4. Close NuPhyIO, update the keyboard to official firmware `1.0.16.6`, switch
   to wired mode, and connect a USB-C data cable.
5. Choose **Connect and Enable**. The app backs up the complete keymap,
   installs the verified F13-F24 profile, verifies the full readback, and
   initializes supported lighting.

Bluetooth remains an input-only path. Live keymap and lighting management
requires USB-C or the verified U1 2.4G route. Do not remove
`~/Library/Application Support/Air75AgentBridge/Backups` while the installed
keymap is active.
