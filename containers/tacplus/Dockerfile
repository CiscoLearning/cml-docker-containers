FROM debian:trixie-slim AS builder

ARG version
# This strips everything after the first hyphen
ARG version_only=${version%%-*}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends curl make gcc flex bison libwrap0-dev libnsl-dev libcrypt-dev libc6-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

WORKDIR /opt
RUN curl -k -O "https://shrubbery.net/pub/tac_plus/tacacs-${version_only}.tar.gz" && tar xzf tacacs-${version_only}.tar.gz

WORKDIR /opt/tacacs-${version_only}
RUN ./configure --without-libwrap --prefix=/usr/local && make && make install && rm /opt/tacacs-${version_only}.tar.gz


FROM debian:trixie-slim
COPY --from=builder /usr/local/ /usr/local/

# library dependencies... just copy them over
COPY --from=builder /usr/lib/x86_64-linux-gnu/libwrap* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libnsl* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libtirpc* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libgssapi* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libkrb5* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libk5crypto* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libkeyutils* /usr/lib/x86_64-linux-gnu/


EXPOSE 49/tcp

ENV LD_LIBRARY_PATH="/usr/local/lib"
# https://manpages.ubuntu.com/manpages/xenial/man5/tac_plus.conf.5.html
# -t to log to console
# -G Remain in the foreground, but not single-threaded nor logging to the tty.
# -C Specify the configuration file name.  The -C option is required.
# -d8, d16: authorization and authentication debugging
# -l log file location
CMD [ "/usr/local/sbin/tac_plus", "-t", "-G", "-C", "/etc/tac_plus.conf", "-d8", "-d16", "-l", "/var/log/tac_plus.log"]

