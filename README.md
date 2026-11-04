# R2Kernel

R2Kernel is a subsystem-oriented robotics runtime platform with:

- a proprietary runtime/control bundle
- Apache-2.0 SDKs, tutorials, and public source

This entry repository corresponds to release `v1.0.0` (version
`1.0.0`). It contains generated installation and release metadata;
SDK/tutorial source and documentation live in separate repositories.

## Download Notice

Official R2Kernel distribution endpoints may record download and installation
metadata, including install session ID, client IP address, user agent, requested
release, platform, architecture, artifact name, response status, and requested
artifact size (the stored size of the requested artifact, not bytes received).
This data is used for artifact delivery, release diagnostics, abuse
investigation, security, and distribution reliability. See the
[Distribution And Licensing](https://docs.r2kernel.org/reference/distribution-and-licensing/) and installed notices.

## Quick Start

Ubuntu / Debian package prerequisites for the commands below:

```bash
sudo apt update
sudo apt install -y ca-certificates curl git python3 python3-venv python3-pip libzmq5
```

The fixed installation entry requires `curl` to select and download a release.

The Linux product config enables managed PTP time sync by default. A product
install into a protected prefix, such as the default, can register five
installer-managed systemd units:

- `r2kernel-control.service`, which runs as the non-root `r2kernel` account
- `r2kernel-resourced.service`
- `r2kernel-timesyncd.service`
- `r2kernel-terminal-login.service` and `r2kernel-https-settings.service`, two
  root-only helpers for Terminal local OS login and Console HTTPS settings,
  installed together with the Control service

A user prefix installs without system services. If you skip service setup,
switch `time_sync.management_mode=external` when you do not want
installer-managed time sync, or install the services later with
`<prefix>/bin/r2kernel-system-service-install`.

The installer-managed time-sync path keeps transient state under
`/run/r2kernel/time-sync`, not inside the install prefix.

The install script runs as the current user first and requests `sudo` only when
the selected prefix or system service registration needs elevated privileges.
Before any `sudo` prompt it parses every argument and checks the prefix
location with the downloaded, hash-verified installer; checks that need the
release or root privileges run after elevation, before anything is downloaded
or installed. It elevates only for a protected prefix (root-owned, not a
symbolic link and not group/other writable): a user prefix (for example in your
home directory) installs without `sudo`, and system service registration needs
a protected prefix such as the default. An installer running as root refuses
any other prefix.

The prefix must be a dedicated directory. System locations such as `/`,
`/usr`, `/usr/local` or `/opt`, home directories and world-writable or sticky
directories are refused. An existing directory that is not empty is used only
when it holds an earlier R2Kernel installation; otherwise the installer stops
and names the entries it found. In an R2Kernel prefix the installer replaces
only what an earlier R2Kernel install created; a foreign `bin`, `lib` or other
product entry stops the installation with an error naming that path. The
uninstaller removes only the entries R2Kernel manages and lists anything else
it leaves in the prefix.

The selected release's script pins the SHA256 of the installer binary and of the
release manifest, and the installer refuses a manifest whose bytes or release
version differ. Release locations must use `https://`; `R2KERNEL_ALLOW_PLAIN_HTTP=1`
is an explicit opt-in for a trusted local mirror. With a distribution token,
curl 7.58 or later is required: the token is read from a private header file and
never sent to another host on a redirect.

Interactive install:

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://download.r2kernel.org/install.sh | sh
```

This fixed URL defaults to the current stable release. Use
`--version 1.0.0` to select this repository's release, or
`--channel beta` to use the beta channel. Choose one selection option; other
installer arguments are passed through. See the
[Installation Reference](https://docs.r2kernel.org/reference/installation-reference/#exact-release-selection)
for commands and selection rules. This repository's `install.sh` and its asset
in [Releases](https://github.com/r2kernel/r2kernel/releases) remain fixed to `1.0.0`.

The default interactive flow uses a full-screen terminal installer when a TTY is
available. To force the line-based prompt flow instead:

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://download.r2kernel.org/install.sh | sh -s -- --no-tui
```

Runtime license acceptance is manual only. The installer does not support an
automatic license-acceptance flag.

Options given to the installer are used as given; the wizard asks only the
remaining questions. Every option that takes a value accepts `--option VALUE`
and `--option=VALUE`. `--non-interactive` (alias `--yes`) never prompts: a
missing decision, such as `--existing-prefix overwrite|abort` for a non-empty
prefix, is an error, and a release that requires license acceptance is refused.

To register the Linux privileged services during the manual installation flow:

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://download.r2kernel.org/install.sh | sh -s -- --system-services install
```

The default install prefix is `/opt/r2kernel`; `<prefix>` below means the
selected prefix. To use a development user prefix:

```bash
curl --proto '=https' --tlsv1.2 -fsSL https://download.r2kernel.org/install.sh | sh -s -- --prefix ~/.local/r2kernel
```

For this custom prefix, source its generated environment file before using
installed SDK/runtime commands or tutorials:

```bash
. "$HOME/.local/r2kernel/env.sh"
```

For custom public spec YAML with this prefix, keep the installed spec available
as fallback with an overlay path:

```bash
. "$HOME/.local/r2kernel/env.sh"
export R2KERNEL_SPEC_PATH=/path/to/custom_spec:$R2KERNEL_SPEC_ROOT
```

## What Gets Installed

- runtime payload under `<prefix>/runtime`
- top-level entry points under `<prefix>/bin`, `<prefix>/spec`, and `<prefix>/config.yaml`
- shell environment helper under `<prefix>/env.sh`
- C++ SDK under `<prefix>/sdk/cpp`
- Python SDK wheel under `<prefix>/sdk/python`
- guided tutorials under `<prefix>/tutorials`
- QA fixtures under `<prefix>/runtime/tools/qa/fixtures`
- license and notice documents under `<prefix>/licenses`
- service unit sources under `<prefix>/systemd`
- runtime state and logs under `<prefix>/var`
- uninstaller under `<prefix>/bin/r2kernel-uninstall`
- optional Linux privileged services via `r2kernel-system-service-install`

The installer prepares a versioned Python environment with the SDK and declared
dependencies under `<prefix>/sdk/python/environments`; `sdk/python/current`
selects the active one. Sourcing `env.sh` selects that interpreter for installed
tutorials and exports `R2KERNEL_PYTHON` for runtime use. Normal installed use does
not require another virtual environment or an SDK checkout. Managed service and
package launches use the managed interpreter, unless an explicit package
interpreter is configured; shell activation alone does not change their policy.

For an isolated development shell, source the runtime environment **before**
activating a separate venv. Do not source `env.sh` again afterwards: it can put
the managed interpreter ahead of the development one. Use the host Python to
create the development environment:

```bash
. <prefix>/env.sh
unset PYTHONPATH
/usr/bin/python3 -m venv r2kernel-quickstart
. r2kernel-quickstart/bin/activate
python -m pip install <prefix>/sdk/python/r2kernel_client-*.whl
```

Clearing `PYTHONPATH` removes the installed SDK import path injected by `env.sh`,
so development uses the venv's wheel or editable SDK. Re-add unrelated custom
import paths explicitly if needed. This does not change `R2KERNEL_PYTHON`.

Guided tutorials and advanced runtime exercises are installed into the local
runtime prefix:

```bash
cd <prefix>
ls tutorials sdk/python
```

Clone the SDK source repo only when you need editable SDK development,
source-level SDK tests, or full source inspection:

```bash
git clone https://github.com/r2kernel/sdk.git r2kernel-sdk
```

For editable SDK development, use the development venv above, then:

```bash
cd r2kernel-sdk
python -m pip install -e sdk/python
```

Robotics application demos are maintained separately from this split core
distribution. Follow the published documentation for the appropriate demo;
they are not contents of the entry repository.

Then follow the guided learning path from the activated shell and the installed
`<prefix>` tree.

Many runnable tutorials use more than one terminal:

- one terminal for the installed control backend
- one or more additional terminals for simulator, gateway, component, compound,
  or application subsystem processes

Long-running tutorial processes usually stay up until you stop them with
`Ctrl-C`.

If you want to build installed C++ tutorials, install a host compiler toolchain
first. Add `cmake` when you also want to rebuild the public C++ SDK source
from an editable checkout.

Ubuntu / Debian:

```bash
sudo apt update
sudo apt install -y build-essential cmake
```

The public C++ tutorial build scripts reuse the installed SDK/runtime under
`<prefix>`, so `cargo` is not required for the normal installed-user flow.

The public C++ SDK source can also be rebuilt against the installed runtime core
library:

```bash
cmake -S sdk/cpp -B build/r2kernel-client-cpp \
  -DR2KERNEL_RUST_CORE_DIR=<prefix>/runtime/lib
cmake --build build/r2kernel-client-cpp
```

## Documentation

- [Published docs](https://docs.r2kernel.org/)
- [Installation guide](https://docs.r2kernel.org/getting-started/installation/)
- [Quickstart](https://docs.r2kernel.org/getting-started/quickstart/)
- [Developer guide](https://docs.r2kernel.org/develop/developer-guide/)

## Feedback

Use [R2Kernel Issues](https://github.com/r2kernel/r2kernel/issues) for bug reports, feature requests,
usage questions, and SDK or documentation feedback. Include the release version,
affected component, environment, and a minimal reproducer where applicable.

## Split Distribution

- this entry repository: generated `README.md`, `install.sh`, `r2kernel.repos`,
  and `release.json`
- [SDK source](https://github.com/r2kernel/sdk.git): public Python/C++ SDKs, tutorials, QA
  fixtures, public specs, and C ABI headers
- [Documentation source](https://github.com/r2kernel/docs.git): documentation and site tooling
- installer download service: proprietary runtime/control binaries and
  installable SDK artifacts

Private runtime implementation and Rust/Core source are not published in the
SDK repository.

## Licensing

- runtime installer-delivered payloads: proprietary runtime license
- SDKs, tutorials, docs, and public source: Apache-2.0

See the installed license/notice files and
[Distribution And Licensing](https://docs.r2kernel.org/reference/distribution-and-licensing/) for details.
