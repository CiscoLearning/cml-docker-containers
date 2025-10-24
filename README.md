# Automation for building CML Docker Containers

[![ISO Release](https://github.com/CiscoLearning/cml-docker-containers/actions/workflows/iso-release.yml/badge.svg)](https://github.com/CiscoLearning/cml-docker-containers/actions/workflows/iso-release.yml)

<!--toc:start-->
- [Automation for building CML Docker Containers](#automation-for-building-cml-docker-containers)
  - [Project overview](#project-overview)
  - [Quickstart](#quickstart)
  - [Dependencies](#dependencies)
  - [How discovery & selection work](#how-discovery-selection-work)
  - [Building (local development)](#building-local-development)
  - [ISO splitting (optional)](#iso-splitting-optional)
  - [Results (what is produced & where)](#results-what-is-produced-where)
  - [Contributing: Adding a new container](#contributing-adding-a-new-container)
  - [CI: GitHub Actions](#ci-github-actions)
  - [Handling Multi-Container (Docker Compose) Solutions](#handling-multi-container-docker-compose-solutions)
  - [Special nodes](#special-nodes)
    - [IOS XRd](#ios-xrd)
    - [Netflow](#netflow)
    - [Splunk](#splunk)
    <!--toc:end-->

---

## Project overview

This repository contains automation and templates to build container images, node definitions and image definitions for use with CML (tested for CML 2.9+). Most container specs in this repository pull software from Docker Hub or public resources; a few require additional manual content (see [Special nodes](#special-nodes)).

<details><summary>Debian packaging</summary>

> [!NOTE]
> Debian package creation is usually not needed!

A single package name variable `PKG` controls the Debian package name and also the output directory under `BUILD/debian/<PKG>/...`. It is defined centrally in `templates/pkg.mk` and used by both the root and per-module Makefiles. By default `PKG=refplat-images-docker`.

</details>

## Quickstart

Build everything locally:

```sh
# build the reference platform ISO
make iso
```

Other, more advanced examples and targets (usually not needed unless developing):

```sh
# build all enabled containers and generate definitions
make

# build a single container (development)
make -C <container-dir>

# build ISOs grouped by per-module iso-name suffixes
make iso

# preview ISO groups and module assignments
make iso-list

# clean ISO outputs and staging
make clean-iso

# build the Debian package (requires packaging tools)
make deb
```

Inspect generated files and package:

- Definitions and images: `BUILD/debian/refplat-images-docker/var/lib/libvirt/images/...` (uses `PKG`; default shown)
- ISOs: `docker-refplat-images<SFX>-<TS>.iso` in repository root
- Debian package: `*.deb`, `*.buildinfo`, `*.changelog`

## Dependencies

Recommended environment: Ubuntu 24.04 (local VM or developer machine).

Required for building and packaging:

- Docker (engine/CLI)
- make
- xorriso (for ISO creation)
  - Linux (Debian/Ubuntu): `sudo apt-get install xorriso`
  - macOS (Homebrew): `brew install xorriso`

For building the .deb package you also need:

- dpkg-dev
- debhelper
- fakeroot

If you only need to build images (no Debian package, no ISOs), you only need `make` and Docker.

## How discovery & selection work

- Discovery: the build system (and CI) scans top-level subdirectories for a `Dockerfile`. Each such directory is treated as a container specification.
- Skip / opt-out: to exclude a container from builds (both local and CI), place an empty file named `.disabled` in that container directory (for example: `chrome/.disabled`). The top-level Makefile and per-directory recipes honor this file and will skip building and definition generation, printing a clear message.
- Output layout: builders and templates create the YAML files and image tarballs under `BUILD/debian/<PKG>/var/lib/libvirt/images/...` so the structure matches what CML expects on the server (default `PKG=refplat-images-docker`).

## Building (local development)

1. Build a single container:

```sh
make -C chrome   # example: builds chrome container and definitions
```

1. Build the images (but don't build any deb or ISO):

```sh
make
```

1. Build the Debian package:

```sh
make deb
```

1. Build ISOs (split by group suffixes):

```sh
make iso
```

**Notes:**

- Per-container Makefiles usually include `../templates/build.mk`. Use an existing container (for example `chrome/` or `nginx/`) as a template when adding a new container.
- If a `.disabled` file exists in a container directory, `make -C <dir>` will skip building that container and print a message.
- Modules may override image preparation via `PREPARE_IMAGE_CMD` in their `Makefile`. This command replaces the default `docker buildx` step (e.g., pulling and tagging a pre-built image).

## ISO splitting (optional)

You can split the output into multiple ISO images by placing a small file named `iso-name` in container subdirectories. The file content determines the ISO group suffix.

- File: `<module>/iso-name`
- Content: a suffix string like `""` (empty), `-extras`, `-big`, etc.
- Default: if `iso-name` is missing, the module belongs to the main ISO (empty suffix).
- Command: `make iso` builds one ISO per discovered suffix group using volume label `REFPLAT`.
- Listing: `make iso-list` shows discovered groups and module assignments.
- Cleaning: `make clean-iso` removes ISO files and staging directories.

Example:

```sh
# assign nginx to the "extras" ISO
echo -extras > nginx/iso-name

# build split ISOs
make iso
# outputs: docker-refplat-images-<TS>.iso (main), docker-refplat-images-extras-<TS>.iso
```

Notes:

- The ISO build stages files into `BUILD/debian/<PKG>/var/lib/libvirt/images/iso-staging<SFX>` and uses symlinks with `xorriso -as mkisofs -r -J -V REFPLAT -follow-links` so file contents are included even if staged via links.
- Always build modules before `make iso` so their tarballs and YAMLs exist; otherwise, symlink targets will be missing.
- If group assignments or files changed, run `make clean-iso` before rebuilding ISOs to avoid stale links.

## Results (what is produced & where)

- Running the tooling produces image tarballs and YAML definitions under:

```plain
BUILD/debian/<PKG>/var/lib/libvirt/images/<...>
```

- The Debian package is produced as `<package>.deb` (see `make deb`).
- Split ISO images are produced as `docker-refplat-images<SFX>-<TS>.iso`.

ISOs and .deb files are placed in the repository root. The generated tree
mirrors the CML server layout so files may be copied to
`/var/lib/libvirt/images/...` on the server.

## Contributing: Adding a new container

Follow these guidelines to add a container that builds locally and in CI.

Minimum directory layout (required files)

```plain
mycontainer/
  Dockerfile                 # required for discovery
  Makefile                   # usually: sym-link to ../templates/build.mk
  vars.mk                    # required metadata (see below)
  node-definition            # required: template used for node YAML
```

**Important:** `node-definition` is required: the `definitions` recipe uses this template to create the YAML file placed in the `BUILD/debian/<PKG>/` tree.

Minimum `vars.mk` example

```makefile
NAME=mycontainer
VERSION=1.0
DESC=Short description
FULLDESC=Longer, user-facing description
```

Requirements and recommendations

- `Dockerfile` must exist for discovery.
- Prefer to sym-link `../templates/build.mk` to your `Makefile` unless you have specialized needs.
- Output expectations:
  - Image tarball (e.g., `$(NTAG).tar.gz`) must appear under `BUILD/debian/<PKG>/var/lib/libvirt/images/...`.
  - Definition YAMLs must be generated into that same area.
- To opt out of builds, add an empty `.disabled` file in the container directory.
- If your container uses a prebuilt image (e.g., from Docker Hub), override the build step by setting `PREPARE_IMAGE_CMD` in your module `Makefile`.

Local test flow

1. Build image and tarball:

```sh
make -C mycontainer
```

1. Build the package locally:

```sh
make iso
```

1. Confirm files:

- `BUILD/debian/<PKG>/var/lib/libvirt/images/...`
- `*.iso`

## CI: GitHub Actions

Use the Actions UI "Run workflow" button or the GitHub CLI:

```sh
# run workflow on 'dev' without creating a release
gh workflow run iso-release --ref dev

# run and create a release
gh workflow run iso-release --ref main -f release_tag=v1.2.3 -f release_name="Release name"
```

## Handling Multi-Container (Docker Compose) Solutions

> [!TIP]
> TL;DR -- Don't try to create multi-container node definitions, they will very likely **not work**!

Cisco Modeling Labs (CML) is designed to treat each node in a topology as a single, self-contained service or application. While it might be tempting to directly deploy multi-container applications, often defined using `docker-compose`, into CML by attempting to split them into individual CML nodes, this approach is generally not recommended and can lead to significant complications.

**Why direct decomposition of Docker Compose is problematic in CML:**

- **Single Node, Single Container Model**: CML's architecture assumes a one-to-one relationship between a CML node and a container image. `docker-compose` solutions, by definition, orchestrate multiple containers that are tightly coupled and rely on specific internal networking configurations managed by `docker-compose`.
- **Networking Complexity**: `docker-compose` automatically sets up internal networks and service discovery for its constituent containers. Trying to replicate this complex internal networking using CML's external connections between individual nodes is incredibly difficult and prone to errors. CML's fabric is not designed to manage the intricate inter-container communication typically handled by `docker-compose`.
- **Increased Potential for Errors**: Attempting to manually stitch together `docker-compose` components as separate CML nodes can lead to misconfigurations, broken dependencies, and unpredictable behavior, making troubleshooting very challenging.

**Recommended Approach: Utilize an Ubuntu VM Node for Docker Compose Solutions**

For complex, multi-container applications that require `docker-compose` orchestration (e.g., Netbox, GitLab), the recommended and most robust solution within CML is to deploy them inside a single Ubuntu virtual machine (VM) node. This approach leverages the VM's capabilities to host the entire `docker-compose` environment.

**Steps for deploying a Docker Compose solution in a CML Ubuntu VM:**

1. **Add an Ubuntu Node**: In your CML lab, add an Ubuntu VM node to your topology.
1. **Install Docker and Docker Compose**: Once the Ubuntu VM is running, connect to it and install Docker Engine and Docker Compose (or Docker CLI with Compose features) within the VM.
1. **Deploy your Application**: Copy your `docker-compose.yml` file and any necessary application data into the Ubuntu VM.
1. **Run Docker Compose**: Execute `docker-compose up -d` (or `docker compose up -d`) within the Ubuntu VM to start your multi-container application.
1. **Create a Custom Image (Optional but Recommended)**: After successfully deploying and configuring your application within the Ubuntu VM, you can create a custom image from its current state. This allows you to save the pre-configured VM as a new, custom node type, which can then be easily reused in future labs without repeating the setup steps. This custom image acts as a 'snapshot' of your configured environment.

This method ensures that the `docker-compose` application runs in its intended environment, with its internal networking and dependencies managed correctly, while CML interacts with this single, self-contained Ubuntu VM node. This aligns with CML's design philosophy and provides a much more stable and manageable solution for advanced container deployments.

## Special nodes

### IOS XRd

XRd builds require a binary XRd container from Cisco (licensing). Place the downloaded file (for example `xrd-control-plane-container-x86.<version>.tgz`) into the `xrd/` directory and ensure `vars.mk` matches the version. The build process will extract and process that archive.

### Netflow

Netflow depends on an older Debian package that is not present in modern distributions; Netflow is disabled by default.

### Splunk

Splunk images are large and disabled by default. Consider keeping Splunk out of automated builds unless required. When creating ISOs, Splunk is put into its own ISO (using the `iso-name` file in the module dir).

---
