FROM debian:12-slim

RUN apt-get update && apt-get install -y wget gnupg && \
    echo "deb [trusted=yes] https://downloads.osmocom.org/packages/osmocom:/latest/Debian_12 ./" > /etc/apt/sources.list.d/osmocom-latest.list && \
    apt-get update

# Install component
RUN apt-get install -y osmo-msc && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY common/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["osmo-msc", "-c", "/etc/osmocom/osmo-msc.cfg"]
