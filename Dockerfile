# ── Stage 1: Build ────────────────────────────────────────────────────────────
FROM node:20-slim AS builder

# Build tools for native addons (tree-sitter, @ladybugdb/core)
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 make g++ cmake git ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY package*.json ./
RUN npm ci

COPY tsconfig*.json ./
COPY src ./src
COPY scripts ./scripts
COPY vendor ./vendor
RUN npm run build

# ── Stage 2: Runtime ──────────────────────────────────────────────────────────
FROM node:20-slim

# Runtime: git (clone on start) + libs for native .node addons
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates python3 make g++ cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

# Copy compiled CLI + vendor
COPY --from=builder /build/dist ./dist
COPY --from=builder /build/vendor ./vendor

COPY docker-start.sh /app/docker-start.sh
RUN chmod +x /app/docker-start.sh

EXPOSE 4747

CMD ["/app/docker-start.sh"]
