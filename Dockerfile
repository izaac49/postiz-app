# ---------- deps ----------
FROM node:22-alpine AS deps
WORKDIR /app
RUN apk add --no-cache libc6-compat python3 make g++

# Use EXACT pnpm version expected by lockfile
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

# ---------- build ----------
FROM deps AS build
ENV NODE_OPTIONS=--max-old-space-size=4096
COPY . .
RUN pnpm run prisma-generate
RUN pnpm -C apps/backend build
RUN pnpm -C apps/frontend build

# ---------- run ----------
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/apps ./apps
COPY --from=build /app/package.json ./package.json

EXPOSE 3000
CMD ["node", "apps/backend/dist/main.js"]
