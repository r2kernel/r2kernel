<div align="center">

# R2Kernel

### Robotics Runtime Kernel

**Runtime infrastructure for portable robotics software.**

Build robotics applications against consistent interfaces across simulation and physical hardware, without binding application logic to one robot, framework, or vendor.

[Releases](https://github.com/r2kernel/r2kernel/releases) · [Start here](#start-here) · [Source model](#availability-and-source-model)

</div>

---

## What is R2Kernel?

R2Kernel is a runtime foundation for composing, connecting, and operating modular robotics software. It is designed to:

- run and coordinate robotics software components;
- preserve application-facing interfaces between simulation and real hardware;
- isolate applications from device-, framework-, and vendor-specific implementations; and
- provide a stable distribution boundary for runtime, SDK, protocol, and integration releases.

> This repository is the official product, installation, and release entry point. It is not the source repository for the R2Kernel core runtime.

## Start here

| Goal | Destination |
| --- | --- |
| Install or update the runtime | [Official releases](https://github.com/r2kernel/r2kernel/releases) |
| Verify a download | Checksums, signatures, and release notes attached to the matching release |
| Learn the platform | Documentation repository, linked here when published |
| Build an application | SDK and example repositories, linked here when published |
| Report a vulnerability | Follow the private reporting instructions in the [Security](#security) section |

## Installation

Official installers and packages are published only through this repository's [Releases](https://github.com/r2kernel/r2kernel/releases). The installer on the default branch will always target the release currently published through this repository:

```sh
curl -fsSL https://raw.githubusercontent.com/r2kernel/r2kernel/main/install.sh | sh
```

Until the first signed release is available, treat this repository as a pre-release entry point. For security-sensitive environments, download and inspect `install.sh` before execution and verify the matching release checksum and signature.

## Availability and source model

| Component | Availability | Source availability |
| --- | --- | --- |
| R2Kernel Runtime | Free official binary releases | Core runtime source is not public |
| R2Kernel SDK | Development libraries | Open source when published |
| Client libraries | Language-specific interfaces | Open source when published |
| Protocols and interfaces | Public specifications | Public when published |
| Tutorials and examples | Reference code | Open source when published |
| Selected adapters | Repository-specific releases | Defined by each repository |
| Enterprise and OEM support | Separate agreement | Not applicable |

Free use and open source are not the same thing. Each repository and release carries its own license. No open-source license should be inferred for the runtime binary or another artifact unless the relevant repository or release explicitly states one.

## Repository contract

Product documentation and policy files are maintained deliberately. Release automation may update only the generated distribution files:

| File | Owner |
| --- | --- |
| `README.md` | Product-maintained |
| `install.sh` | Release automation |
| `r2kernel.repos` | Release automation |
| `release.json` | Release automation |
| Checksums, signatures, and release assets | Release automation |

This separation keeps the product page stable while allowing every published release to carry exact installer, source-manifest, and verification metadata.

## Documentation and SDK

Documentation, SDKs, examples, interfaces, and selected adapters will live in dedicated repositories under the [R2Kernel organization](https://github.com/r2kernel). Their repositories will state their own support scope and license.

Editable source checkout is intended for SDK, interface, documentation, example, and integration work. The core runtime is installed as an official binary.

## Status and platforms

R2Kernel is currently in **Beta**. Initial release tooling targets Linux on x86_64 and AArch64. Each release defines its exact platform, compatibility, upgrade, and support matrix.

## Security

Use only artifacts published by the [R2Kernel organization](https://github.com/r2kernel). Security reports must be submitted privately and should not be disclosed through a public issue before a fix is available. A dedicated security policy and reporting channel will be published before public binary distribution.

## Governance

R2Kernel is a founder-led robotics infrastructure project operated by **LRH Korea Inc.**

- **Founder and Principal Architect:** Justin H. Kang
- Project direction and official releases are managed by LRH Korea.
- External contributions are accepted only in repositories explicitly designated as open source.
- Commercial support, sponsored development, OEM integration, and long-term support are handled separately.

## Legal

Repository-specific licenses govern the material in each repository. Runtime binaries, SDK source, documentation, and other artifacts may be distributed under different terms. R2Kernel names, logos, and related marks are governed separately from source-code licenses.
