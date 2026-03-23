# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM node:20-slim AS builder

# Build tools for native addons (tree-sitter, @ladybugdb/core)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ cmake git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY package*.json ./
COPY scripts ./scripts
COPY tsconfig*.json ./
COPY src ./src
COPY vendor ./vendor
RUN npm ci

# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
# Ubuntu 24.04 (Noble) has GLIBC 2.39 — required by @ladybugdb/core prebuilt
# which links against GLIBC_2.38. node:20-slim (Debian Bookworm) only has 2.36.
FROM ubuntu:24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./

# Copy compiled node_modules (with native addons) from builder
COPY --from=builder /build/node_modules ./node_modules

# Copy compiled CLI + vendor
COPY --from=builder /build/dist ./dist
COPY --from=builder /build/vendor ./vendor

COPY docker-start.sh /app/docker-start.sh
RUN chmod +x /app/docker-start.sh

EXPOSE 4747

CMD ["/app/docker-start.sh"]
