#Base
FROM node:20-bookworm-slim AS base
WORKDIR /app
ENV NODE_ENV=production
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl ca-certificates tini \
 && rm -rf /var/lib/apt/lists/* \
 && npm i -g pnpm

#Deps
FROM base AS deps
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
# Dev deps'ler de kalsın (tsx, prisma cli vs. runtime'da lazım)
RUN pnpm install --no-frozen-lockfile

#Runtime
FROM base AS runtime
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
EXPOSE 8080

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["sh", "-c", "pnpm prisma migrate deploy && pnpm prisma generate && pnpm exec tsx src/index.ts"]
