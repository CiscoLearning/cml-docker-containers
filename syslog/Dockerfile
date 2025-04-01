FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends syslog-ng && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY syslog-ng.conf /etc/syslog-ng/syslog-ng.conf

CMD ["syslog-ng", "--stderr", "--verbose", "--foreground", "--no-caps"]

