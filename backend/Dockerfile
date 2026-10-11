# ─── Stage 1: Build TypeScript ──────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json tsconfig.json ./
RUN npm ci

# Copy source code and contracts
COPY src ./src
COPY openapi.json ./

# Compile TypeScript and bundle artifacts
RUN npm run build

# ─── Stage 2: Production Runner ─────────────────────────────────────────────
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Install production dependencies only
COPY package*.json ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy compiled JavaScript and contract ABIs from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/openapi.json ./openapi.json

# Security: Run as non-root user
USER node

EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start the Sahaay production server
CMD ["node", "dist/index.js"]
