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
FROM node:20-slim

# Runtime: git for cloning MRCH on startup
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./

# Copy compiled node_modules (with native addons already built) from builder
COPY --from=builder /build/node_modules ./node_modules

# Copy compiled CLI + vendor
COPY --from=builder /build/dist ./dist
COPY --from=builder /build/vendor ./vendor

COPY docker-start.sh /app/docker-start.sh
RUN chmod +x /app/docker-start.sh

EXPOSE 4747

CMD ["/app/docker-start.sh"]
