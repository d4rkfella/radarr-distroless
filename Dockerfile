FROM docker.io/debian:bullseye-slim AS build

ARG VERSION=5.19.0.9697

WORKDIR /workdir

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates wget libsqlite3-0 catatonit \
    && mkdir -p app /rootfs/bin /rootfs/usr/lib/ \
    && wget -qO- "https://radarr.servarr.com/v1/update/develop/updatefile?version=${VERSION}&os=linux&runtime=netcore&arch=x64" | \
    tar xvz --strip-components=1 --directory=app \
    && printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[d4rkfella](https://github.com/d4rkfella)\n" "develop" "${VERSION}" > ./app/package_info \
    && chown -R root:root /app && chmod -R 755 /app \
    && rm -rf /tmp/* /app/Radarr.Update \
    && mv app /rootfs/ \
    && cp -p /usr/lib/*-linux-gnu/libsqlite3.so.0 /rootfs/usr/lib/libsqlite3.so.0 \
    && cp -p /usr/bin/catatonit /rootfs/bin/catatonit

FROM mcr.microsoft.com/dotnet/runtime-deps:6.0.35-cbl-mariner2.0-distroless

WORKDIR /app

USER 65532

COPY --from=build /rootfs/app /app
COPY --from=build /rootfs/bin/catatonit /bin/catatonit
COPY --from=build /rootfs/usr/lib/libsqlite3.so.0 /usr/lib/libsqlite3.so.0

EXPOSE 7878

# NOTE: enabling running containers with read only filesystem
#       https://github.com/dotnet/docs/issues/10217
ENV XDG_CONFIG_HOME=/config \
    DOTNET_SYSTEM_GLOBALIZATION_PREDEFINED_CULTURES_ONLY=false \
    DOTNET_EnableDiagnostics="0" \
    UMASK="0002" \
    TZ="Etc/UTC"

ENTRYPOINT ["/bin/catatonit", "--", "/app/Radarr", "-nobrowser"]

LABEL org.opencontainers.image.source="https://github.com/Radarr/Radarr"
