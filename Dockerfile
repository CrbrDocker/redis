# redis on the crbr Debian base image.
# Built and pushed by .github/workflows/build.yml (native per-arch, OCI +
# provenance + SBOM). BASE_DIGEST records the exact base index the image was
# built from so the rebuild gate can detect a refreshed base.
ARG BASE_IMAGE=ghcr.io/crbrdocker/debian:stable
FROM ${BASE_IMAGE}
ARG BASE_IMAGE
ARG IMAGE_VERSION=""
ARG IMAGE_REVISION=""
ARG IMAGE_CREATED=""
ARG IMAGE_SOURCE=""
ARG BASE_DIGEST=""

COPY --chmod=755 install-redis.sh /usr/local/bin/install-redis.sh
RUN /usr/local/bin/install-redis.sh && rm -f /usr/local/bin/install-redis.sh

LABEL org.opencontainers.image.title="redis" \
      org.opencontainers.image.description="Redis on the crbr Debian base image" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.revision="${IMAGE_REVISION}" \
      org.opencontainers.image.created="${IMAGE_CREATED}" \
      org.opencontainers.image.source="${IMAGE_SOURCE}" \
      org.opencontainers.image.base.name="${BASE_IMAGE}" \
      org.opencontainers.image.base.digest="${BASE_DIGEST}"

VOLUME /srv/data/redis
WORKDIR /srv/data/redis

STOPSIGNAL SIGTERM

EXPOSE 6379/tcp

CMD ["crbr-redis-start.sh"]
