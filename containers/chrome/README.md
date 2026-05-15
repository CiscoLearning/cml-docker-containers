# README

The build script checks online what's the latest available Chromium package is
in the Debian Trixie repository and uses that. This is done via the
`get_version.sh` script which is called in the `vars.mk` sub-makefile.
