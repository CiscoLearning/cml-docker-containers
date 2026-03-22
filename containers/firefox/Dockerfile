FROM debian:trixie-slim

ARG uid
ARG version

RUN test -n "${uid}" || (echo "docker build-arg uid must be set" && false)

RUN apt-get update && apt-get upgrade -y && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y curl ca-certificates
RUN install -d -m 0755 /etc/apt/keyrings && install -d -m 0755 /etc/apt/preferences.d
# https://keyserver.ubuntu.com/pks/lookup?search=C0BA5CE6DC6315A3&fingerprint=on&op=index
COPY 35baa0b33e9eb396f59ca838c0ba5ce6dc6315a3.asc /etc/apt/trusted.gpg.d/mozilla.gpg
COPY mozilla-signing-key.gpg /etc/apt/keyrings/packages.mozilla.org.asc
RUN echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" >/etc/apt/sources.list.d/mozilla.list
# RUN <<EOF
# echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" >/etc/apt/sources.list.d/mozilla.list
# mkdir /etc/apt/preferences.d
# echo 'Package: *
# Pin: origin packages.mozilla.org
# Pin-Priority: 1000
# 
# Package: firefox*
# Pin: release o=Ubuntu
# Pin-Priority: -1
# ' >/etc/apt/preferences.d/mozilla
# EOF
# 
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  ca-certificates \
  i3 \
  xdotool \
  firefox=${version} && \
  apt-get autoremove && apt-get clean && rm -rf /var/lib/apt/lists/* && \
  useradd -l --create-home --shell /bin/bash -u ${uid} --user-group debian

# prevent windows "Welcome to Firefox" and "Firefox privacy notice" tabs
COPY policies.json /usr/lib/firefox/distribution/policies.json
COPY i3config /home/debian/.config/i3/config
RUN mkdir -p /var/run/dbus && \
  ln -s /home/debian/.dbus-socket /var/run/dbus/system_bus_socket && \
  chown -R debian:debian /home/debian/.config /var/run/dbus/system_bus_socket

USER debian
COPY start.sh /start.sh
CMD ["/start.sh"]

