# Next steps toward the six-key developer surface

The foundation is intentionally complete before the custom workflow is
implemented. The smallest safe sequence for the next phase is:

1. **Define the platform-neutral contract.** Add `DeveloperKey` and
   `DeveloperKeyState` models for AGENT, TEST, BUILD, GIT, SHIP, and TALK. Keep
   physical key identity, software action, status, and optional Fn-layer action
   separate.
2. **Add an integration protocol.** Define adapters for Codex, shell commands,
   Git, build/test runners, IDE actions, and CI without importing any of them
   into the Air75 driver.
3. **Connect status to the existing lighting API.** Map each developer key to
   `SignalLightLayout` through the generic `KeyboardLightingDriver`. Keep the
   current read-before-write, D8 ACK, D2 readback, and rollback rules.
4. **Choose an event owner.** Start with the existing HID/input path and
   explicit user permissions. Only investigate DriverKit if physical-source
   separation becomes a demonstrated requirement.
5. **Add deterministic simulation tests.** Exercise every key/action/status
   transition without hardware, including stale-state decay, error recovery,
   duplicate assignment, and reboot/persistence behavior.
6. **Add one production-route acceptance slice.** Prove one key end-to-end on
   USB-C first: physical event -> integration action -> status update -> D8
   write -> D2 readback -> restore. Repeat on U1 2.4G only after USB-C evidence.
7. **Implement the remaining five keys incrementally.** Do not introduce all
   six workflows in one change; each integration should carry its own runtime
   evidence and a fail-closed behavior.

The immediate next implementation task should be step 1 plus a simulated
state machine. It is independent of Codex and hardware, so it can be reviewed
before any new HID writes or external automation are authorized.
