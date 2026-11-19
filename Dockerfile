FROM node:24.22.3-bookworm-slim AS build
ARG WHERDR_VERSION=v3.2.0
WORKDIR /src/wherdr

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

COPY wherdr-open-network-banner.patch /tmp/wherdr-open-network-banner.patch
RUN git clone --depth 1 --branch "$WHERDR_VERSION" https://github.com/afloury/wherdr.git . \
    && git apply /tmp/wherdr-open-network-banner.patch \
    && npm ci --no-audit --no-fund \
    && npm run build

FROM node:24.22.3-bookworm-slim
ARG HC_VERSION=0.1.21

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git netcat-openbsd openssh-client procps \
    && rm -rf /var/lib/apt/lists/*

RUN set -eu; \
    case "$(dpkg --print-architecture)" in \
        amd64) target=linux-x86_64 ;; \
        arm64) target=linux-aarch64 ;; \
        *) echo "Unsupported architecture for herdr-core" >&2; exit 1 ;; \
    esac; \
    tmpdir="$(mktemp -d)"; \
    cd "$tmpdir"; \
    curl -fsSL --retry 3 "https://releases.herdr.dev/core/$HC_VERSION/manifest.json" -o manifest.json; \
    url="$(node -p 'require("./manifest.json").targets[process.argv[1]].url' "$target")"; \
    checksum="$(node -p 'require("./manifest.json").targets[process.argv[1]].sha256' "$target")"; \
    curl -fsSL --retry 3 "$url" -o hc.tar.gz; \
    printf '%s  hc.tar.gz\n' "$checksum" | sha256sum -c -; \
    tar -xzf hc.tar.gz herdr-core; \
    install -m 0755 herdr-core /usr/local/bin/herdr-core; \
    ln -s herdr-core /usr/local/bin/hc; \
    cd /; \
    rm -rf "$tmpdir"

RUN groupmod --new-name coder node \
    && usermod --login coder --gid coder --home /home/coder --move-home \
        --shell /bin/bash --password '*' node

WORKDIR /opt/wherdr
COPY --from=build /src/wherdr/.output/ ./.output/
COPY --from=build /src/wherdr/docs/ ./docs/
COPY --from=build /src/wherdr/LICENSE /usr/share/doc/wherdr/LICENSE
COPY licenses/herdr-core.txt /usr/share/doc/herdr-core/LICENSE
COPY --chmod=0755 entrypoint.sh /usr/local/bin/wherdr-entrypoint

ENV HOME=/home/coder \
    SHELL=/bin/bash \
    HOST=127.0.0.1 \
    PORT=8080 \
    XDG_RUNTIME_DIR=/home/coder/.local/run \
    HC_SOCKET=/home/coder/.local/run/herdr-core/default.sock \
    DATA_DIR=/home/coder/wherdr-data

USER coder
ENTRYPOINT ["/usr/local/bin/wherdr-entrypoint"]
