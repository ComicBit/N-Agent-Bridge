# Security Policy

## Supported versions

Security fixes prioritize `main` and the latest GitHub Release. Development
builds are not Apple-notarized production packages, but security reports are
still welcome.

## Private reports

Use the repository’s private **Security → Report a vulnerability** channel.
Do not publish any of the following in a public issue:

- exploitable HID write sequences or reproduction steps that could damage a
  device;
- user credentials, tokens, chat content, or local private data;
- undisclosed device serial numbers, firmware, or vendor material;
- code-signing, notarization, or supply-chain credentials.

Include the affected version, macOS version, keyboard model and firmware,
connection method, reproduction steps, and impact. Redact personal
information and raw captures before sending them.

## Security boundary

The project does not bypass macOS Input Monitoring, Accessibility, or
Gatekeeper authorization. Unknown keyboards and unverified vendor-HID
protocols are non-writable by default. Do not propose disabling system
security controls as a fix.
