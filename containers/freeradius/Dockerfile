FROM debian:trixie-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends freeradius tini expect && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

EXPOSE 1812/udp
EXPOSE 1813/udp

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/usr/local/bin/start.sh"]
