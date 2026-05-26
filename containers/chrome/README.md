# README

The build script checks online for the latest available Chromium package
in the Debian Trixie repository and uses it. This is done via the
`get_version.sh` script, which is called from the `vars.mk` sub-makefile.
