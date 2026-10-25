# Build stage: Flutter SDK pinned to a stable tag, cloned from the official repo.
FROM debian:trixie-20261020-slim AS build
ARG FLUTTER_VERSION=3.47.8
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl git unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter
ENV PATH="/opt/flutter/bin:${PATH}"
RUN flutter config --no-analytics --enable-web && flutter precache --web
WORKDIR /src
COPY pubspec.yaml ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

# Runtime stage: static files served by nginx; config.json is written at container start.
FROM nginx:1.31.2-alpine
COPY --from=build /src/build/web /usr/share/nginx/html
COPY docker/40-runtime-config.sh /docker-entrypoint.d/40-runtime-config.sh
EXPOSE 80
