FROM docker.io/library/alpine:3.21 AS build

ARG VERSION=5.18.4.9674

WORKDIR /workdir

RUN apk add --no-cache \
    ca-certificates \
    sqlite-libs \
    && mkdir -p app /rootfs/usr/lib/ \
    && wget -qO- "https://radarr.servarr.com/v1/update/master/updatefile?version=${VERSION}&os=linuxmusl&runtime=netcore&arch=x64" | \
    tar xvz --strip-components=1 --directory=app \
    && mv app /rootfs/ \
    && find / -name "libsqlite*" -exec cp {} /rootfs/usr/lib/ \;

WORKDIR /rootfs

COPY --chmod=755 --chown=0:0 --from=busybox:1.37.0-musl /bin/wget /rootfs/wget

FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.35-cbl-mariner2.0-distroless

USER 65532

COPY --from=build --chmod=755 /rootfs /

EXPOSE 7878

# NOTE: enabling running containers with read only filesystem
#       https://github.com/dotnet/docs/issues/10217
ENV XDG_CONFIG_HOME=/config \
    DOTNET_SYSTEM_GLOBALIZATION_PREDEFINED_CULTURES_ONLY=false \
    COMPlus_EnableDiagnostics=0

ENTRYPOINT [ "/app/Radarr" ]
CMD [ "-nobrowser" ]
