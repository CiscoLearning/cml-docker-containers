# Automation for building CML Docker Containers

This repository contains the automation and scripts to build the Docker
container images, node definition and image definitions which are included in
the Cisco Modeling Labs product.

In addition, there are two node definitions which are not included:

- **IOS XRd** [Binary IOS XRd images can be downloaded here](https://software.cisco.com/download/home/286331236/type).
- **Netflow** This requires a very old Debian distro, the netflow package has
disappeared in newer Debian distros.

## Dependencies

For this to work, it is recommended to run this inside of a Ubuntu or Debian VM
with development packages and Docker installed. In particular

- Docker <https://docs.docker.com/engine/install/ubuntu/> or <https://docs.docker.com/engine/install/debian/>
- dpkg-dev
- devscripts

If no Debian package should be built, then only `make` is required which can be
installed using `apt install make`.

## Building

Either run `make` at the top level to build all container images and the
associated node and image definitions. Or `cd` into a specific directory and
run `make` there.

> [!NOTE]
> netflow and IOS XRd are "off" by default. To turn either of them "on", rename
> the Dockerfile in the respective directory, removing the "-off" part from the
> filename.

## Results

The files are built in the `BUILD/debian/refplat-images-docker/...` directory.
Copy the resulting node and image definitions to your CML server into the same
place `/var/lib/libvirt/images/...`.

As an option, a Debian package can be built which can also be installed on the
CML server. The package build process can be started via `make deb` and
requires the aforementioned dev tools and scripts installed.

## Automated Container Builds with GitHub Actions

This repository uses GitHub Actions to automatically build container images and Debian packages whenever you push to the `main` branch, create a version tag, or trigger a build manually.

### How automatic builds work

- **Discovery:** The workflow scans the repository for subdirectories containing a `Dockerfile` and skips any directory that contains a `.disabled` file.
- **Build:** Each enabled container directory is built sequentially using its `Makefile` (which must output a `.tar.gz` archive under `BUILD/debian/`).
- **Debian Packaging:** After building containers, the workflow updates `BUILD/debian/changelog` with a timestamped version and builds the main `.deb` package. The `.deb` includes all `.tar.gz` container payloads.
- **Artifacts and Release:** The workflow uploads only the Debian packaging artifacts (`.deb`, `.changes`, `.buildinfo`) to Actions and optionally creates a GitHub Release that attaches these files for public download.

#### Skipping a container build

To exclude a container from automated builds:

1. Place an empty file named `.disabled` inside the container’s directory.
2. The workflow will detect `.disabled` and skip building that container entirely.

Example:
```
chrome/
  Dockerfile
  .disabled    <-- causes 'chrome' to be skipped by auto-builds
```

### Manually triggering a build with GitHub CLI

You can run builds on any branch or with custom inputs using the GitHub CLI:

```
# Trigger an auto-build on the 'dev' branch (no release)
gh workflow run build-and-release.yml --ref dev -f create_release=false

# Trigger a release build on 'main' with a specific tag and release name
gh workflow run build-and-release.yml --ref main -f create_release=true -f release_tag=v1.2.3 -f release_name="Custom Release"
```
- Replace `build-and-release.yml` with the actual workflow filename if needed.
- Use `--ref <branch>` to select which branch’s workflow should run.
- The inputs `create_release`, `release_tag`, and `release_name` control whether and how a release is created.

### Further notes

- **Permissions:** For release creation to work, the workflow must have `permissions: contents: write` (see workflow YAML).
- **Artifact Retention:** Actions artifacts are kept for a limited time (default: 90 days; set to 10 days in this repo).
- **Release Assets:** Files attached to a GitHub Release persist until deleted.

---

## Specific note on XRd

The file that can be downloaded from CCO is e.g.
`xrd-control-plane-container-x86.24.4.2.tgz` for version 24.4.2. This is a
tar/gz archive which includes the actual Docker image. Put the downloaded file
into the `xrd` directory, make sure the version matches what is defined in the
`vars` file. The process will then extract the needed image file from the
archive and process it.
