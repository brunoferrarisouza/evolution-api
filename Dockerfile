# ==========================================
# Stage 1: Builder
# ==========================================
FROM node:22-alpine AS builder

# Instalar dependências necessárias para build
RUN apk update && apk add --no-cache \
    git \
    ffmpeg \
    wget \
    curl \
    bash \
    openssl \
    python3 \
    make \
    g++ \
    cairo-dev \
    jpeg-dev \
    pango-dev \
    giflib-dev \
    pixman-dev

WORKDIR /evolution

# Copiar arquivos de configuração
COPY package*.json ./
COPY tsconfig.json ./
COPY tsup.config.ts ./

# Configurar npm para lidar melhor com dependências nativas
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV SHARP_IGNORE_GLOBAL_LIBVIPS=1

# Instalar dependências (usar ci se tiver lock file atualizado)
RUN npm install --loglevel=verbose || npm ci

# Copiar código fonte
COPY ./src ./src
COPY ./public ./public
COPY ./prisma ./prisma
COPY ./manager ./manager
COPY ./.env.example ./.env
COPY ./runWithProvider.js ./
COPY ./Docker ./Docker

# Preparar scripts e gerar database
RUN chmod +x ./Docker/scripts/* && \
    (dos2unix ./Docker/scripts/* 2>/dev/null || true)

# Gerar Prisma Client
RUN npx prisma generate

# Build do projeto
RUN npm run build

# ==========================================
# Stage 2: Runtime (imagem final)
# ==========================================
FROM node:22-alpine

# Instalar apenas dependências de runtime
RUN apk update && apk add --no-cache \
    tzdata \
    ffmpeg \
    bash \
    openssl \
    cairo \
    jpeg \
    pango \
    giflib \
    pixman

WORKDIR /evolution

# Copiar do builder
COPY --from=builder /evolution/package.json ./
COPY --from=builder /evolution/package-lock.json ./
COPY --from=builder /evolution/node_modules ./node_modules
COPY --from=builder /evolution/dist ./dist
COPY --from=builder /evolution/prisma ./prisma
COPY --from=builder /evolution/manager ./manager
COPY --from=builder /evolution/public ./public
COPY --from=builder /evolution/.env ./
COPY --from=builder /evolution/Docker ./Docker
COPY --from=builder /evolution/runWithProvider.js ./

# Variáveis de ambiente
ENV NODE_ENV=production
ENV TZ=America/Sao_Paulo

# Expor porta
EXPOSE 8080

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Comando de inicialização
CMD ["node", "dist/index.js"]
