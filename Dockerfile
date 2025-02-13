FROM mcr.microsoft.com/dotnet/runtime-deps:9.0.2-alpine3.21-extra AS build

ARG VERSION=5.19.0.9697

WORKDIR /workdir

RUN apk add --no-cache \
        ca-certificates \
        catatonit \
        sqlite-libs \
    && mkdir -p app/bin /rootfs/bin \
    && wget -qO- "https://radarr.servarr.com/v1/update/develop/updatefile?version=${VERSION}&os=linuxmusl&runtime=netcore&arch=x64" | \
    tar xvz --strip-components=1 --directory=app/bin \
    && printf "UpdateMethod=docker\nBranch=%s\nPackageVersion=%s\nPackageAuthor=[d4rkfella](https://github.com/d4rkfella)\n" "develop" "${VERSION}" > ./app/package_info \
    && chown -R root:root ./app && chmod -R 755 ./app \
    && rm -rf /tmp/* ./app/bin/Radarr.Update \
    && mv app /rootfs/ \
    && cp -p /usr/bin/catatonit /rootfs/bin/catatonit \
    && find /lib -type d -empty -delete \
    && rm -rf /lib/apk \
    && rm -rf /lib/sysctl.d

FROM scratch

WORKDIR /app

USER 65532

COPY --from=build /rootfs/app /app
COPY --from=build /rootfs/bin/catatonit /bin/catatonit
COPY --from=build /usr/share/icu /usr/share/icu
COPY --from=build /etc/passwd /etc/passwd
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY /usr/lib/libz.so.* /usr/lib/
COPY /usr/lib/libcrypto.so.* /usr/lib/
COPY /usr/lib/libssl.so.* /usr/lib/
COPY /usr/lib/libicui18n.so.* /usr/lib/
COPY /usr/lib/libicudata.so.* /usr/lib/
COPY /usr/lib/libicuuc.so.* /usr/lib/
COPY /usr/lib/libgcc_s.so.* /usr/lib/
COPY /usr/lib/libstdc++.so.* /usr/lib/
COPY /lib/ld-musl-x86_64.so.* /lib/
COPY /usr/lib/libsqlite3.so.* /usr/lib/

VOLUME ["/config"]

ENV XDG_CONFIG_HOME=/config \
    DOTNET_EnableDiagnostics="0" \
    UMASK="0002"

ENTRYPOINT ["/bin/catatonit", "--", "/app/bin/Radarr", "-nobrowser"]

LABEL org.opencontainers.image.source="https://github.com/Radarr/Radarr"
