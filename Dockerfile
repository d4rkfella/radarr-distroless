FROM cgr.dev/chainguard/wolfi-base:latest@sha256:9c86299eaeb27bfec41728fc56a19fa00656c001c0f01228b203379e5ac3ef28 AS build

# renovate: datasource=github-tags depName=Radarr/Radarr
ARG RADARR_VERSION=v5.17.2.9580
# renovate: datasource=github-releases depName=openSUSE/catatonit
ARG CATATONIT_VERSION=v0.2.1

WORKDIR /rootfs

RUN apk add --no-cache \
        curl \
        gpg \
        gpg-agent \
        gnupg-dirmngr && \
    mkdir -p app/bin usr/bin && \
    curl -fsSLO --output-dir /tmp "https://github.com/openSUSE/catatonit/releases/download/${CATATONIT_VERSION}/catatonit.x86_64{,.asc}" && \
    gpg --keyserver keyserver.ubuntu.com --recv-keys 5F36C6C61B5460124A75F5A69E18AA267DDB8DB4 && \
    gpg --verify /tmp/catatonit.x86_64.asc /tmp/catatonit.x86_64 && \
    mv /tmp/catatonit.x86_64 usr/bin/catatonit && \
    chmod +x usr/bin/catatonit && \
    curl -fsSL "https://github.com/Radarr/Radarr/releases/download/${RADARR_VERSION}/Radarr.master.${RADARR_VERSION#v}.linux-core-x64.tar.gz" | \
    tar xvz --strip-components=1 --directory=app/bin && \
    printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[d4rkfella](https://github.com/d4rkfella)\n" "master" "${RADARR_VERSION#v}" > app/package_info && \
    rm -rf app/bin/Radarr.Update

FROM cgr.dev/chainguard/wolfi-base:latest@sha256:9c86299eaeb27bfec41728fc56a19fa00656c001c0f01228b203379e5ac3ef28

RUN apk add --no-cache \
        readline \
        tzdata \
        icu-libs \
        sqlite-libs && \
    echo "radarr:x:65532:65532::/nonexistent:/sbin/nologin" > /etc/passwd && \
    echo "radarr:x:65532:" > /etc/group && \
    rm -rf /home/* && \
    find / \( -path /proc -o -path /sys -o -path /dev \) -prune -o -type l -exec sh -c 'if [ "$(readlink "$1")" = "/bin/busybox" ]; then echo "$1"; fi' _ {} \; | xargs rm && \
    apk del --no-cache --purge wolfi-base busybox wolfi-keys apk-tools readline

COPY --from=build /rootfs /

USER radarr:radarr

WORKDIR /app

VOLUME ["/config"]
EXPOSE 7878

ENV XDG_CONFIG_HOME=/config \
    DOTNET_RUNNING_IN_CONTAINER=true \
    DOTNET_EnableDiagnostics="0" \
    TZ="Etc/UTC" \
    UMASK="0002" 

ENTRYPOINT [ "catatonit", "--", "/app/bin/Radarr" ]
CMD [ "-nobrowser" ]

LABEL org.opencontainers.image.source="https://github.com/Radarr/Radarr"
