# Runtime image ("yolk") for a Next.js egg on Pelican Panel.
#
# This image does NOT contain your app. Pelican mounts the server's files at
# /home/container and runs the egg's startup command there, so the image only
# provides Node.js, the package managers and the tools needed to install and
# build a Next.js project.
#
# Build for another Node version with:  --build-arg NODE_VERSION=26
ARG NODE_VERSION=25

FROM --platform=$TARGETOS/$TARGETARCH node:${NODE_VERSION}-trixie-slim

LABEL org.opencontainers.image.title="Pelican Next.js yolk" \
      org.opencontainers.image.description="Node.js runtime image for running Next.js apps on Pelican Panel"

# Pelican/Wings sends the egg's stop command; ^C maps to SIGINT.
STOPSIGNAL SIGINT

# git: clone/pull the app      build-essential + python3: native npm modules
# openssl: Prisma and friends   iproute2: used by the entrypoint
# tini: PID 1, forwards signals and reaps child processes
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        openssh-client \
        openssl \
        iproute2 \
        tzdata \
        tini \
        zip \
        unzip \
        tar \
        python3 \
        build-essential \
    && rm -rf /var/lib/apt/lists/*

# pnpm and yarn via Corepack. Node 25+ no longer bundles Corepack, so install
# it explicitly (--force replaces the bundled copy on older Node versions).
RUN npm install --global --force corepack@latest \
    && corepack enable \
    && npm cache clean --force

# The user Pelican expects. Its home is the mounted server directory.
RUN useradd -m -d /home/container -s /bin/bash container

USER container
ENV USER=container \
    HOME=/home/container \
    # Wings runs the container with a read-only root filesystem and no TTY:
    # let Corepack fetch pnpm/yarn without asking.
    COREPACK_ENABLE_DOWNLOAD_PROMPT=0 \
    NEXT_TELEMETRY_DISABLED=1 \
    # Docker sets HOSTNAME to the container ID, which makes a Next.js
    # standalone server bind to the wrong interface. Listen on all of them.
    HOSTNAME=0.0.0.0
WORKDIR /home/container

COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]
CMD ["/entrypoint.sh"]