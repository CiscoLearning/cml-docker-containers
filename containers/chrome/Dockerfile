FROM debian:trixie-slim

ARG uid

RUN test -n "${uid}" || (echo "docker build-arg uid must be set" && false)

RUN apt-get update && apt-get upgrade -y && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  ca-certificates \
  curl \
  i3 \
  xdotool \
  chromium && \
  apt-get autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* && \
  useradd -l --create-home --shell /bin/bash -u ${uid} --user-group debian
COPY i3config /home/debian/.config/i3/config
RUN mkdir -p /var/run/dbus && \
  ln -s /home/debian/.dbus-socket /var/run/dbus/system_bus_socket && \
  chown -R debian:debian /home/debian/.config /var/run/dbus/system_bus_socket

USER debian
COPY start.sh /start.sh
CMD ["/start.sh"]
