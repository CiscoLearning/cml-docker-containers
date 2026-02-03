#!/bin/bash

# fetch the APK index for the latest stable Alpine
url="https://dl-cdn.alpinelinux.org/alpine/latest-stable/community/x86_64/APKINDEX.tar.gz"
curl -s "$url" |
  tar -xzO -f - APKINDEX |

  # extract package version
  awk -F: '/^P:frr$/,/^$/{ if ($1 == "V") print $2 }' |

  # sort with version sort and get the latest (last line)
  sort -V | tail -n1
