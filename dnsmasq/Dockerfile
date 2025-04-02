FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends dnsmasq dnsutils && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

COPY dnsmasq.conf /etc/dnsmasq.conf

CMD ["dnsmasq", "--no-daemon", "--log-queries", "--log-dhcp", "--log-facility=-"]

