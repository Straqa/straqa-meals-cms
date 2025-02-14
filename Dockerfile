# Use Node.js 20 for compatibility
FROM node:20-alpine AS base

# Step 1. Rebuild the source code only when needed
FROM base AS builder

WORKDIR /app

# Install required build tools and libraries for sharp and other native modules
RUN apk add --no-cache \
    libc6-compat \
    build-base \
    python3 \
    libstdc++ \
    bash

# Copy package definition files
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./

# Install dependencies based on the preferred package manager
RUN \
    if [ -f yarn.lock ]; then yarn --frozen-lockfile --network-timeout 100000; \
    elif [ -f package-lock.json ]; then npm ci; \
    elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i; \
    else echo "Warning: Lockfile not found." && npm install; \
    fi

# Copy source files
COPY . .

# Define build-time arguments
ARG DATABASE_URI
ARG PAYLOAD_SECRET
ARG S3_ENDPOINT
ARG S3_ACCESS_KEY_ID
ARG S3_SECRET_ACCESS_KEY
ARG S3_BUCKET
ARG S3_REGION
ARG S3_FORCE_PATH_STYLE
ARG S3_PREFIX

# Set environment variables for the build stage
ENV DATABASE_URI=$DATABASE_URI
ENV PAYLOAD_SECRET=$PAYLOAD_SECRET
ENV S3_ENDPOINT=$S3_ENDPOINT
ENV S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
ENV SHARP_SKIP_AUTOINSTALL=true

# Disable telemetry during build
ENV NEXT_TELEMETRY_DISABLED 1
ENV NODE_ENV=production

# Build Next.js
RUN \
    if [ -f yarn.lock ]; then yarn build; \
    elif [ -f package-lock.json ]; then npm run build; \
    elif [ -f pnpm-lock.yaml ]; then pnpm build; \
    else npm run build; \
    fi

# Step 2. Production image
FROM base AS runner

WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
USER nextjs

# Disable telemetry during runtime
ENV NEXT_TELEMETRY_DISABLED 1

# Copy built assets
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Define build-time arguments
ARG DATABASE_URI
ARG PAYLOAD_SECRET
ARG S3_ENDPOINT
ARG S3_ACCESS_KEY_ID
ARG S3_SECRET_ACCESS_KEY
ARG S3_BUCKET
ARG S3_REGION
ARG S3_FORCE_PATH_STYLE
ARG S3_PREFIX

# Set environment variables for the build stage
ENV DATABASE_URI=$DATABASE_URI
ENV PAYLOAD_SECRET=$PAYLOAD_SECRET
ENV S3_ENDPOINT=$S3_ENDPOINT
ENV S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
ENV SHARP_SKIP_AUTOINSTALL=true

# Environment variables
ENV NEXT_TELEMETRY_DISABLED 1
ENV PORT=9000

# Start the Next.js server
CMD ["pnpm", "run", "start"]
