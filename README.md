# Automation for building CML Docker Containers

This repository automates building Docker images and the node/image definition files used by Cisco Modeling Labs (CML). It produces artifacts and a Debian package (.deb) that can be installed on a CML server. The output mirrors the CML server layout so artifacts can be copied directly to `/var/lib/libvirt/images/...`.

**Table of contents**

- [Project overview](#project-overview)
- [Quickstart](#quickstart)
- [Dependencies](#dependencies)
- [How discovery & selection work](#how-discovery-selection-work)
- [Building (local development)](#building-local-development)
- [Results (what is produced & where)](#results-what-is-produced-where)
- [Contributing: adding a new container](#contributing-adding-a-new-container)
- [CI: GitHub Actions, artifacts & releases](#ci-github-actions-artifacts-releases)
- [Troubleshooting](#troubleshooting)
- [Special nodes (IOS XRd / Netflow / Splunk)](#special-nodes)
- [Pro tips](#pro-tips)
- [Appendix: examples & useful commands](#appendix-examples-useful-commands)

---

## Project overview

This repository contains automation and templates to build container images, node definitions and image definitions for use with CML (tested for CML 2.9+). Most container specs in this repository pull software from Docker Hub or public resources; a few require additional manual content (see Special nodes).

## Quickstart

Build everything locally:

```sh
# build all enabled containers and generate definitions
make

# build a single container (development)
make -C <container-dir>

# build the Debian package (requires packaging tools)
make deb
```

Inspect generated files and package:

- Definitions and images: `BUILD/debian/refplat-images-docker/var/lib/libvirt/images/...`
- Debian package: `*.deb`, `*.buildinfo`, `*.changelog`

## Dependencies

Recommended environment: Ubuntu 24.04 (local VM or developer machine).

Required for building and packaging:

- Docker (engine/CLI)

For building the .deb package you also need:

- dpkg-dev
- devscripts
- fakeroot
- debhelper
- build-essential

If you only need to build images (no Debian package), you only need `make` and Docker.

## How discovery & selection work

- Discovery: the build system (and CI) scans top-level subdirectories for a `Dockerfile`. Each such directory is treated as a container specification.
- Skip / opt-out: to exclude a container from builds (both local and CI), place an empty file named `.disabled` in that container directory (for example: `chrome/.disabled`). The top-level Makefile and per-directory recipes honor this file and will skip building and definition generation, printing a clear message.
- Output layout: builders and templates create the YAML files and image tarballs under `BUILD/debian/refplat-images-docker/var/lib/libvirt/images/...` so the structure matches what CML expects on the server.

## Building (local development)

1. Build a single container:

```sh
make chrome   # example: builds chrome container and definitions
```

2. Build everything:

```sh
make
```

3. Build the Debian package:

```sh
make deb
```

**Notes:**

- Per-container Makefiles usually soft-link to  `../templates/makefile`. Use an existing container (for example `chrome/` or `nginx/`) as a template when adding a new container.
- If a `.disabled` file exists in a container directory, `make -C <dir>` will skip building that container and print a message.

## Results (what is produced & where)

- Image tarballs and YAML definitions are placed under:

```
BUILD/debian/refplat-images-docker/var/lib/libvirt/images/<...>
```

- The Debian package is produced as `<package>.deb` (see `make deb`).

The generated tree mirrors the CML server layout so files may be copied to `/var/lib/libvirt/images/...` on the server.

## Contributing: Adding a new container

Follow these guidelines to add a container that builds locally and in CI.

Minimum directory layout (required files)

```
mycontainer/
  Dockerfile                 # required for discovery
  Makefile                   # usually: soft-link to ../templates/makefile
  vars.mk                    # required metadata (see below)
  node-definition            # required: template used for node YAML
```

**Important:** `node-definition` is required: the `definitions` recipe uses this template to create the YAML file placed in the `BUILD/debian/refplat-images-docker/` tree.

Minimum `vars.mk` example

```makefile
NAME=mycontainer
VERSION=1.0
DESC=Short description
FULLDESC=Longer, user-facing description
```

Requirements and recommendations

- `Dockerfile` must exist for discovery.
- Prefer to `include ../templates/makefile` in your `Makefile` unless you have specialized needs.
- Output expectations:
  - Image tarball (e.g., `$(NTAG).tar.gz`) must appear under `BUILD/debian/refplat-images-docker/var/lib/libvirt/images/...`.
  - Definition YAMLs must be generated into that same area.
- To opt out of builds, add an empty `.disabled` file in the container directory.

Local test flow

1. Build image and tarball:

```sh
make -C mycontainer
```

2. Generate definitions (if not already generated by build):

```sh
make -C mycontainer definitions
```

3. Build the package locally:

```sh
make deb
```

4. Confirm files:

- `BUILD/debian/refplat-images-docker/var/lib/libvirt/images/...`
- `*.deb`

CI test (manual run)

```sh
gh workflow run build-and-release.yml --ref <your-branch> -f create_release=false
```

## CI: GitHub Actions, artifacts & releases

Behavior

- The workflow discovers directories containing `Dockerfile` and without `.disabled` and builds them sequentially.
- After image builds, the workflow updates `BUILD/debian/changelog` and sets a timestamped package version: `<base>+YYYYMMDDHHMMSS` (UTC). The changelog entry message is exactly `auto-built on github on <YYYY-MM-DD HH:MM:SSZ>`.
- The workflow builds the `.deb` package and uploads Debian packaging artifacts: `*.deb`, `*.changes`, and `*.buildinfo`. It also creates a pruned tarball containing only the `var/lib/...` subtree named like `docker-refplat-images-<ts>.tar.gz` and uploads that tarball as an artifact and (optionally) attaches it to a GitHub Release.

**Manual triggers**

Use the Actions UI "Run workflow" button or the GitHub CLI:

```sh
# run workflow on 'dev' without creating a release
gh workflow run build-and-release.yml --ref dev -f create_release=false

# run and create a release
gh workflow run build-and-release.yml --ref main -f create_release=true -f release_tag=v1.2.3 -f release_name="Release name"
```

**Permissions**

- The workflow requires `permissions: contents: write` to create releases using the injected `GITHUB_TOKEN`. If your organization restricts this, use a PAT stored as a repository secret for the release steps or ask an admin to allow write permissions for the workflow.

**Artifact retention and storage**

- Actions artifacts are retained for a limited period; this repository configures `retention-days: 10` for uploaded artifacts.
- Files attached to GitHub Releases persist until manually deleted.

## Troubleshooting

- **Build not skipped even though `.disabled` exists**: ensure the `.disabled` file is in the container directory (e.g., `chrome/.disabled`) and you are running the updated Makefiles. The repository Makefiles include guards that skip builds and definitions when `.disabled` is present.

- **`docker image inspect` or "No such image" errors when generating definitions**: build the image first (`make -C <dir>`) before running `make definitions`. The `definitions` target now checks for the image and will skip if it is missing.

- **CI release step fails with `Resource not accessible by integration` (403)**: confirm `permissions: contents: write` is set and allowed for workflows. If the organization blocks write tokens, use a PAT in repository secrets and modify the release step to use it.

- **Artifacts are large**: consider attaching only the `.deb` to Releases for long-term storage or hosting very large artifacts externally.

## Special nodes

### IOS XRd

XRd builds require a binary XRd container from Cisco (licensing). Place the downloaded file (for example `xrd-control-plane-container-x86.<version>.tgz`) into the `xrd/` directory and ensure `vars.mk` matches the version. The build process will extract and process that archive.

### Netflow

Netflow depends on an older Debian package that is not present in modern distributions; Netflow is disabled by default.

### Splunk

Splunk images are large and disabled by default. Consider keeping Splunk out of automated builds unless required.

## Pro tips

- Copy an existing container directory (e.g., `chrome/` or `nginx/`) when creating a new container — it speeds onboarding and avoids missing variables.
- Keep Docker images small to reduce CI time and storage usage.
- Use the `gh` CLI to trigger workflows and inspect runs (`gh run list`, `gh run view <id>`).

## Appendix: examples & useful commands

- Example skeleton

```
mycontainer/
  Dockerfile
  Makefile (soft-link to ../templates/makefile)
  vars.mk
  node-definition
```

- Useful CI command examples

```sh
# run workflow on a branch without release
gh workflow run build-and-release.yml --ref dev -f create_release=false

# trigger release via workflow dispatch
gh workflow run build-and-release.yml --ref main -f create_release=true -f release_tag=v1.2.3 -f release_name="Release name"
```

---
