# syntax=docker/dockerfile:1
# ---------- Stage 1: build React (CRA) ----------
FROM node:20-alpine AS builder
WORKDIR /app

# CRA nhung REACT_APP_* vao bundle LUC BUILD -> phai truyen bang --build-arg
ARG REACT_APP_API_URL=/api
ENV REACT_APP_API_URL=$REACT_APP_API_URL
# CRA 5 coi warning la error khi CI=true -> tat di cho build khong gay
ENV CI=false
ENV GENERATE_SOURCEMAP=false

COPY package*.json ./
RUN npm install --no-audit --no-fund

COPY . .
RUN npm run build

# ---------- Stage 2: nginx phuc vu static ----------
FROM nginx:1.27-alpine AS runner

RUN apk add --no-cache wget
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/build /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
