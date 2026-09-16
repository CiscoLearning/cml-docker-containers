# README

## Version

How to get the version of the latest-agent:

```plain
$ docker run -it --rm --entrypoint=/bin/bash thousandeyes/enterprise-agent:latest-agent
b1d04ecad96e:/# /usr/bin/te-agent --version
ThousandEyes Agent version 1.221.0 (build aebc68d0161a135dbe6926f9d240f679bbe0e081) Tue Aug 12 18:17:58 UTC 2025
b1d04ecad96e:/#
```

## CML stock node definition

The generated `thousandeyes-ea` node definition targets the **base Enterprise Agent**
(no `te-browserbot` volume). Stock caps keep `NET_ADMIN` only; `SYS_ADMIN` and `MKNOD` are omitted.

BrowserBot / page-load / transaction tests require ThousandEyes host setup
(`configure_docker.sh`, `te-seccomp.json`, `docker_sandbox` AppArmor)
and are **not** part of the CML stock definition.
