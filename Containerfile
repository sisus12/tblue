ARG BASE_IMAGE_NAME="${BASE_IMAGE_NAME:-silverblue}"
ARG IMAGE_FLAVOR="${IMAGE_FLAVOR:-main}"
ARG SOURCE_IMAGE="${SOURCE_IMAGE:-$BASE_IMAGE_NAME-$IMAGE_FLAVOR}"
ARG BASE_IMAGE="ghcr.io/ublue-os/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION:-latest}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION} AS tblue

ARG IMAGE_NAME="${IMAGE_NAME}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

COPY etc /etc
COPY tblue-firstboot /usr/bin

ADD packages.json /tmp/packages.json
ADD build.sh /tmp/build.sh

RUN wget https://copr.fedorainfracloud.org/coprs/lukenukem/asus-linux/repo/fedora-"${FEDORA_MAJOR_VERSION}"/lukenukem-asus-linux-fedora-"${FEDORA_MAJOR_VERSION}".repo -O /etc/yum.repos.d/asus.repo

RUN /tmp/build.sh && \
    pip install --prefix=/usr yafti && \
    systemctl unmask dconf-update.service && \
    systemctl enable dconf-update.service && \
    systemctl enable rpm-ostree-countme.service && \
    systemctl enable tlp.service && \
    systemctl disable NetworkManager-wait-online.service && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/user.conf && \
    sed -i 's/#DefaultTimeoutStopSec.*/DefaultTimeoutStopSec=15s/' /etc/systemd/system.conf && \ 
    git clone https://github.com/CachyOS/CachyOS-Settings.git && \
    cp -r CachyOS-Settings/etc/* /etc/ && \
    cp -r CachyOS-Settings/usr/bin/* /usr/bin/ && \
    find /etc/yum.repos.d/. -type f -not \( -name 'fedora.repo' -or -name 'fedora-updates.repo' \) -delete && \
    rm -rf /tmp/* /var/* && \
    ostree container commit && \
    mkdir -p /var/tmp && \
    chmod -R 1777 /var/tmp
