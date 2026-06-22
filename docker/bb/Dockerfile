FROM debian:12-slim

# Repo Osmocom + tools build + pustaka -dev (libosmocore, csn1, dan komponen libosmo-gprs)
RUN apt-get update && apt-get install -y wget gnupg && \
    echo "deb [trusted=yes] https://downloads.osmocom.org/packages/osmocom:/latest/Debian_12 ./" \
      > /etc/apt/sources.list.d/osmocom-latest.list && \
    apt-get update && \
    apt-get install -y git build-essential libtool pkg-config autoconf automake make shtool \
        libtalloc-dev libsctp-dev libmnl-dev \
        libosmocore-dev libosmo-csn1-dev \
        libosmo-gprs-rlcmac-dev libosmo-gprs-llc-dev libosmo-gprs-gmm-dev \
        libosmo-gprs-sm-dev libosmo-gprs-sndcp-dev && \
    apt-get clean

# Clone + build HANYA host tools: layer23 (mobile) + virtphy -- tanpa firmware ARM
RUN git clone https://gitea.osmocom.org/phone-side/osmocom-bb.git /opt/osmocom-bb
WORKDIR /opt/osmocom-bb/src
RUN make layer23 virtphy

CMD ["/bin/bash"]
