FROM node:22-alpine AS builder

RUN apk update && apk add --no-cache \
    git python3 make g++ \
    cairo-dev jpeg-dev pango-dev giflib-dev pixman-dev

WORKDIR /evolution

COPY package*.json ./

# Mostrar package.json COMPLETO
RUN echo "========== PACKAGE.JSON COMPLETO ==========" && \
    cat package.json && \
    echo "========== FIM PACKAGE.JSON ==========" && \
    echo "" && \
    echo "========== PACKAGE-LOCK.JSON (primeiras 50 linhas) ==========" && \
    head -n 50 package-lock.json 2>/dev/null || echo "Sem package-lock.json"

# Tentar instalar COM output completo
RUN set -x && \
    npm install --verbose 2>&1 || \
    (echo "========== ERRO DO NPM ==========" && \
     tail -n 200 /root/.npm/_logs/*-debug-0.log && \
     exit 1)
