FROM cgr.dev/chainguard/wolfi-base:latest@sha256:91ed94ec4e72368a9b5113f2ffb1d8e783a91db489011a89d9fad3e3816a75ba AS build

# renovate: datasource=github-releases depName=Radarr/Radarr
ARG RADARR_VERSION=v5.19.3.9730

WORKDIR /rootfs

RUN apk add --no-cache \
        curl && \
    mkdir -p app/bin etc && \
    curl -fsSL "https://github.com/Radarr/Radarr/releases/download/${RADARR_VERSION}/Radarr.master.${RADARR_VERSION#v}.linux-core-x64.tar.gz" | \
    tar xvz --strip-components=1 --directory=app/bin && \
    printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[d4rkfella](https://github.com/d4rkfella)\n" "master" "${RADARR_VERSION#v}" > app/package_info && \
    rm -rf app/bin/Radarr.Update && \
    echo "radarr:x:65532:65532::/nonexistent:/sbin/nologin" > etc/passwd && \
    echo "radarr:x:65532:" > etc/group

FROM ghcr.io/d4rkfella/wolfi-dotnet-runtime-deps:latest@sha256:aefd7d9ba541718bdc8669630e92daf47c07c37cd6a8d4f2af856bf76d1e093a

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
