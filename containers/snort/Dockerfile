FROM ciscotalos/snort3:latest
USER root
COPY start-msg /tmp/start-msg
RUN cat /tmp/start-msg >> /home/snorty/.bashrc && rm /tmp/start-msg
USER snorty
