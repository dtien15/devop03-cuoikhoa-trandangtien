# syntax=docker/dockerfile:1
# ---------- Stage 1: cai dependencies (co cache rieng) ----------
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev --no-audit --no-fund

# ---------- Stage 2: runtime ----------
FROM node:20-alpine AS runner
WORKDIR /app

# wget dung cho HEALTHCHECK, tini lam PID 1 de nhan SIGTERM dung cach
RUN apk add --no-cache tini wget

ENV NODE_ENV=production \
    PORT=8000

COPY --from=deps /app/node_modules ./node_modules
COPY --chown=node:node . .

# Chay bang user khong phai root
USER node

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8000/health || exit 1

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["node", "server.js"]
