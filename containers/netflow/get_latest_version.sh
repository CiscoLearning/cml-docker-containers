#!/bin/bash

# fetch the packages file (buster is archived)
url="https://archive.debian.org/debian/dists/buster/main/binary-amd64/Packages.gz"
curl -s "$url" |
  gzip -dc |

  # extract 'Package:' and the next 'Version:'
  awk '/^Package: flow-tools$/,/^$/ {
    if ($1 == "Version:") print $2
  }' |

  # sort with version sort and get the latest (last line)
  sort -V | tail -n1
