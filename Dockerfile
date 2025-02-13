FROM docker.io/debian:bullseye-slim AS build

ARG VERSION=5.19.0.9697

WORKDIR /workdir

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates wget libsqlite3-0 catatonit \
    && mkdir -p app /rootfs/bin /rootfs/usr/lib/ \
    && wget -qO- "https://radarr.servarr.com/v1/update/develop/updatefile?version=${VERSION}&os=linux&runtime=netcore&arch=x64" | \
    tar xvz --strip-components=1 --directory=app \
    && mv app /rootfs/ \
    && cp /usr/lib/*-linux-gnu/libsqlite3.so.0 /rootfs/usr/lib/libsqlite3.so.0 \
    && cp /usr/bin/catatonit /rootfs/bin/catatonit

WORKDIR /rootfs

COPY --chmod=755 --chown=0:0 --from=busybox:1.37.0-musl /bin/wget /rootfs/wget

FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.35-cbl-mariner2.0-distroless

USER 65532

COPY --from=build --chmod=755 /rootfs/app /app
COPY --from=build --chmod=755 /rootfs/bin/catatonit /bin/catatonit
COPY --from=build --chmod=755 /rootfs/usr/lib/libsqlite3.so.0 /usr/lib/libsqlite3.so.0

EXPOSE 7878

# NOTE: enabling running containers with read only filesystem
#       https://github.com/dotnet/docs/issues/10217
ENV XDG_CONFIG_HOME=/config \
    DOTNET_SYSTEM_GLOBALIZATION_PREDEFINED_CULTURES_ONLY=false \
    COMPlus_EnableDiagnostics=0 \
    UMASK="0002" \
    TZ="Etc/UTC"

ENTRYPOINT ["/bin/catatonit", "--", "/app/Radarr", "-nobrowser"]
