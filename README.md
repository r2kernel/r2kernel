<div align="center">

# R2Kernel

### Robotics Runtime Kernel

**Runtime infrastructure for portable robotics software.**

Build robotics applications against consistent interfaces across simulation and physical hardware, without binding application logic to one robot, framework, or vendor.

![Status: Beta](https://img.shields.io/badge/status-beta-A16207?style=flat-square)
![Platform: Linux](https://img.shields.io/badge/platform-Linux-18181B?style=flat-square&logo=linux&logoColor=white)
![Architectures: x86_64 and AArch64](https://img.shields.io/badge/architectures-x86__64%20%7C%20AArch64-334155?style=flat-square)
![Distribution: Official binaries](https://img.shields.io/badge/distribution-official%20binaries-0F766E?style=flat-square)

[Releases](https://github.com/r2kernel/r2kernel/releases) · [Documentation](https://github.com/r2kernel/r2kernel-docs) · [SDK](https://github.com/r2kernel/r2kernel-sdk) · [Demo](https://github.com/r2kernel/r2kernel-demo)

</div>

---

## What is R2Kernel?

R2Kernel is a runtime foundation for composing, connecting, and operating modular robotics software. It is designed to:

- run and coordinate robotics software components;
- preserve application-facing interfaces between simulation and physical hardware;
- isolate applications from device-, framework-, and vendor-specific implementations; and
- provide a stable distribution boundary for runtime, SDK, protocol, and integration releases.

> This repository is the official product, installation, and release entry point. It is not the source repository for the R2Kernel core runtime.

## Start here

| Goal | Destination |
|---|---|
| Install or update the runtime | [Official releases](https://github.com/r2kernel/r2kernel/releases) |
| Learn concepts and APIs | [R2Kernel documentation](https://github.com/r2kernel/r2kernel-docs) |
| Build an application | [R2Kernel SDK](https://github.com/r2kernel/r2kernel-sdk) |
| Run a complete scenario | [R2Kernel demo](https://github.com/r2kernel/r2kernel-demo) |
| Inspect the compatible repository set | [r2kernel.repos](https://github.com/r2kernel/r2kernel/blob/main/r2kernel.repos) |
| Report a vulnerability | Follow the private reporting instructions in [Security](#security) |

## Repository topology

| Repository | Responsibility | Version relationship |
|---|---|---|
| [r2kernel](https://github.com/r2kernel/r2kernel) | Installer, binary releases, checksums, signatures, release notes, and release manifest | Canonical release version |
| [r2kernel-sdk](https://github.com/r2kernel/r2kernel-sdk) | SDKs, public interfaces, protocols, tutorials, and development examples | Pinned by the matching runtime release |
| [r2kernel-docs](https://github.com/r2kernel/r2kernel-docs) | Product concepts, installation guidance, API and release documentation | Pinned by the matching runtime release |
| [r2kernel-demo](https://github.com/r2kernel/r2kernel-demo) | Complete runnable evaluation and learning scenarios | Independent release; declares its tested runtime version |

The repositories are peers within the [R2Kernel organization](https://github.com/r2kernel). Their hierarchy is defined by this product entry point, the Organization profile, and the versioned release manifest—not by nested Git repositories.

## Installation

Official installers and packages are published only through this repository's [Releases](https://github.com/r2kernel/r2kernel/releases). Once the first signed release is available, the installer on the default branch will target the release currently published here:

```sh
curl -fsSL https://raw.githubusercontent.com/r2kernel/r2kernel/main/install.sh | sh
```

Until then, treat this repository as a pre-release entry point. For security-sensitive environments, download and inspect `install.sh` before execution and verify the matching release checksum and signature.

## Versioned repository set

Each official release generates two machine-readable files:

- `r2kernel.repos` pins the compatible SDK and documentation revisions.
- `release.json` describes the release, supported platforms, artifacts, and verification metadata.

This makes a release reproducible without turning the product repository into a monorepo. The demo repository remains independent and states the R2Kernel release against which each demo version was tested.

## Availability and source model

| Component | Availability | Source availability |
|---|---|---|
| R2Kernel Runtime | Free official binary releases | Core runtime source is not public |
| R2Kernel SDK and clients | Development libraries | Open source when published |
| Protocols and interfaces | Integration specifications | Public when published |
| Documentation and examples | Learning and reference material | Open source when published |
| Selected adapters | Repository-specific releases | Defined by each repository |
| Enterprise and OEM support | Separate agreement | Not applicable |

Free use and open source are not the same thing. Each repository and release carries its own license. No open-source license should be inferred for the runtime binary or another artifact unless the relevant repository or release explicitly states one.

## Repository contract

Product documentation and policy files are maintained deliberately. Release automation updates only the generated distribution files:

| File | Maintained by |
|---|---|
| `README.md` | Product maintainers |
| `install.sh` | Release automation |
| `r2kernel.repos` | Release automation |
| `release.json` | Release automation |
| Checksums, signatures, and release assets | Release automation |

SDK and documentation repositories are generated from the corresponding release inputs. Their README files must therefore be produced from maintained templates rather than edited only on GitHub. The demo repository follows its own source and release process.

## Status and platforms

R2Kernel is currently in **Beta**. Initial release tooling targets Linux on x86_64 and AArch64. Each release defines its exact platform support, compatibility boundaries, known limitations, upgrade guidance, and support policy.

## Security

Use only artifacts published by the R2Kernel organization. Security reports must be submitted privately and should not be disclosed through a public issue before a fix is available. A dedicated security policy and private reporting channel will be published before public binary distribution.

## Contributing

Editable source checkout is intended for SDK, interface, documentation, example, and integration work. The core runtime is installed as an official binary.

Before contributing, review the target repository's license, contribution guidance, supported scope, and security policy. External contributions are accepted only in repositories that explicitly say so.

## Governance

R2Kernel is a founder-led robotics infrastructure project operated by **LRH Korea Inc.**

- Founder and Principal Architect: **Justin H. Kang**
- Project direction and official releases are managed by LRH Korea.
- Commercial support, sponsored development, OEM integration, and long-term support are handled separately.

## Legal

Repository-specific licenses govern the material in each repository. Runtime binaries, SDK source, documentation, and other artifacts may be distributed under different terms. R2Kernel names, logos, and related marks are governed separately from source-code licenses.
