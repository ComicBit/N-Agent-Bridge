# NuPhy protocol research sources (2026-07-19)

The conclusions are recorded in `docs/AIR75_V3_PROTOCOL.md`,
`docs/LIGHTING-PROTOCOL.md`, and `BLOCKERS.md`. This file records provenance
for review. Raw captures, including proprietary NuPhyIO JavaScript, are not
committed; the upstream research archive was kept at
`../research-nuphy-20260719/`.

## Official sources

- NuPhyIO configurator: the live application was on `drive.nuphy.io`;
  `io.nuphy.com` was only the marketing shell. The 2026-07-19 bundle was
  `https://drive.nuphy.io/static/js/main.f6f60294.js`. The marketing host
  reset connections with non-browser TLS fingerprints, so capture required a
  browser-like user agent.
- The complete S4 command table came from webpack module 40877; frame
  construction came from module 36937; the S4 mechanical and EG Hall keyboard
  API classes came from module 86736.
- The device catalog, including all VID/PID entries and the U1 dongle `2620`,
  came from the Next.js flight payload.

## Community reverse engineering used for cross-checking

- `kelchm/nuphy-tools`: S4-family `PROTOCOL.md` and `sk` detection method;
- `fldc/nuphyctl`: Rust CLI, Air75 V3 lighting offsets, and WebHID capture
  methodology;
- `Z3R0-CDS/nuphy-linux`: VID/PID entries in udev rules;
- `donn/nudelta` (V1 only) and `nuphy-src/qmk_firmware` (V2 only), which were
  checked and deemed inapplicable to V3.

## Repository tools

- `extract-simple-module.mjs`: extracts a webpack module by ID;
- `air75 led map` and `air75 led get <KEY>`: safe named-key developer
  diagnostics;
- `Air75ProtocolProbe --enumerate`: read-only compatible-interface
  enumeration;
- `Air75ProtocolProbe --hardware-validate`: protected physical validation;
  run only with the ownership conditions in `AGENTS.md`.
