# R2Kernel

R2Kernel™ provides a common runtime for launching, connecting, and monitoring
robot software, on a single host or across multiple hosts within one robot. It
is a project of Librerobotics™.

This repository is the release entry for `v1.0.0` (version
`1.0.0`). It holds the installer bootstrap and the release
metadata. The SDK and the documentation have their own repositories.

## Install

These steps are for Ubuntu and Debian with systemd. Linux packages are available
for `x86_64` and `aarch64`. The `aarch64` packages have not been qualified on ARM
hardware, and R2Kernel has not been qualified for hard real-time use; see
[Support and Compatibility](https://docs.r2kernel.org/reference/support-and-compatibility/).

1. Prepare the host:

   ```bash
   sudo apt update
   sudo apt install -y ca-certificates curl python3 python3-venv
   ```

2. Install the current stable release as your normal user:

   ```bash
   curl --proto '=https' --tlsv1.2 -fsSL https://download.r2kernel.org/install.sh | sh
   ```

   The installer asks you to read and accept the runtime license; acceptance is
   always manual. It requests `sudo` when it needs it and offers to install the
   system services that start the runtime automatically.

   To install exactly this release instead of the current stable one:

   ```bash
   curl --proto '=https' --tlsv1.2 -fsSL https://download.r2kernel.org/install.sh | sh -s -- --version 1.0.0
   ```

   The `install.sh` attached to this release in
   [Releases](https://github.com/r2kernel/r2kernel/releases) is also fixed to `1.0.0`.

3. Check the installation in the default location:

   ```bash
   . /opt/r2kernel/env.sh
   r2kernel status
   ```

The system services include managed PTP time sync on `time_sync.domain` 24, so
a host never announces itself on the default domain 0 of existing PTP equipment.
If something else on the network already uses domain 24, install with
`--system-services skip`, choose another domain as described in
[Time Sync Operations](https://docs.r2kernel.org/operate/time-sync-operations/), and then
register the services as described in the
[Installation Reference](https://docs.r2kernel.org/reference/installation-reference/#system-services).

A new installation serves the Web Console over local HTTP. Read
[Web and API Security](https://docs.r2kernel.org/operate/web-and-api-security/) before
allowing remote access.

For another version or channel, a user-owned location, and every installer
option, see the [Installation Reference](https://docs.r2kernel.org/reference/installation-reference/).
Then continue with the [Quickstart](https://docs.r2kernel.org/getting-started/quickstart/).

## Download notice

The official download service may record the installation session ID, client IP
address, user agent, requested release, platform, architecture, artifact name,
response status, and the stored size of the requested artifact (the size of the
file on the server, not the bytes the client received). Consent records also keep
the network operator derived from the client IP address.

LRH Korea Inc. is responsible for these records. They help us deliver downloads,
find delivery problems, investigate abuse, check license compliance, and keep the
service secure and reliable. Read
[Distribution and Licensing](https://docs.r2kernel.org/reference/distribution-and-licensing/)
and the notices included with your installation.

## Repositories

- This repository: `install.sh`, `release.json` (release metadata), and
  `r2kernel.repos` (the matching SDK and documentation revisions).
- [SDK](https://github.com/r2kernel/sdk.git): the Python and C++ SDKs, tutorials, public
  specifications, and C ABI headers.
- [Documentation](https://github.com/r2kernel/docs.git): the source of the
  [documentation site](https://docs.r2kernel.org/).
- The runtime binaries are delivered by the installer.

## Help

- [Documentation](https://docs.r2kernel.org/) · [Developer guide](https://docs.r2kernel.org/develop/developer-guide/) · [Operations guide](https://docs.r2kernel.org/operate/operator-overview/)
- [Open an issue](https://github.com/r2kernel/r2kernel/issues) to ask a question, report a bug,
  suggest a feature, or share feedback on the SDK or documentation. Include your
  R2Kernel version, the component involved, and how to reproduce the problem.
- Report possible security issues privately through the
  [Librerobotics contact form](https://www.librerobotics.org/#contact), not in
  public issues.

## Licensing

The runtime delivered by the installer is provided under a proprietary license.
The SDK source, specifications, tutorials, and documentation use
**Apache-2.0**. The `libr2kernel_comm` binary bundled with the SDK packages is
under the runtime license until its source is published. Third-party
components have their own license terms and notices. See
[Distribution and Licensing](https://docs.r2kernel.org/reference/distribution-and-licensing/)
for the terms that apply to each part.
