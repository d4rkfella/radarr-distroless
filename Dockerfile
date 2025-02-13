FROM docker.io/library/alpine:3.21 AS build

ARG VERSION=5.19.0.9697

WORKDIR /workdir

RUN apk add --no-cache \
        ca-certificates \
        catatonit \
        sqlite-libs \
    && mkdir -p app/bin /rootfs/bin /rootfs/usr/lib/ \
    && wget -qO- "https://radarr.servarr.com/v1/update/develop/updatefile?version=${VERSION}&os=linuxmusl&runtime=netcore&arch=x64" | \
    tar xvz --strip-components=1 --directory=app/bin \
    && printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[d4rkfella](https://github.com/d4rkfella)\n" "develop" "${VERSION}" > ./app/package_info \
    && chown -R root:root ./app && chmod -R 755 ./app \
    && rm -rf /tmp/* ./app/bin/Radarr.Update \
    && mv app /rootfs/ \
    && cp -p /usr/lib/libsqlite3.so.0 /rootfs/usr/lib/libsqlite3.so.0 \
    && cp -p /usr/bin/catatonit /rootfs/bin/catatonit

FROM mcr.microsoft.com/dotnet/runtime-deps:9.0.2-alpine3.21-extra

WORKDIR /app

USER 65532

COPY --from=build /rootfs/app /app
COPY --from=build /rootfs/bin/catatonit /bin/catatonit
COPY --from=build /rootfs/usr/lib/libsqlite3.so.0 /usr/lib/libsqlite3.so.0

VOLUME ["/config"]

ENV XDG_CONFIG_HOME=/config \
    DOTNET_EnableDiagnostics="0" \
    UMASK="0002" \
    TZ="Etc/UTC"

ENTRYPOINT ["/bin/catatonit", "--", "/app/bin/Radarr", "-nobrowser"]

LABEL org.opencontainers.image.source="https://github.com/Radarr/Radarr"
