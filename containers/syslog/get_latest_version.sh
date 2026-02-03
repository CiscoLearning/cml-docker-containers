#!/bin/bash

# fetch the packages file
url="https://deb.debian.org/debian/dists/trixie/main/binary-amd64/Packages.gz"
curl -s "$url" |
  gzip -dc |

  # extract 'Package:' and the next 'Version:'
  awk '/^Package: syslog-ng$/,/^$/ {
    if ($1 == "Version:") print $2
  }' |

  # sort with version sort and get the latest (last line)
  sort -V | tail -n1
