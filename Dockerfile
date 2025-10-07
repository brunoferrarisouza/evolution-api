FROM node:22-alpine AS builder

RUN apk update && apk add --no-cache \
    git python3 make g++ \
    cairo-dev jpeg-dev pango-dev giflib-dev pixman-dev

WORKDIR /evolution

COPY package*.json ./

# Mostrar conteúdo do package.json
RUN cat package.json

# Tentar instalar SEM silent
RUN npm install --verbose 2>&1 | tee /tmp/npm-install.log || \
    (echo "========== NPM INSTALL FALHOU ==========" && \
     cat /tmp/npm-install.log && \
     cat /root/.npm/_logs/*-debug-0.log && \
     exit 1)
