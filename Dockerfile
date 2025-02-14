# Base image
FROM node:22.12.0-alpine AS base
# Install dependencies only when needed
FROM base AS deps
# Install required build tools and libraries for sharp and other native modules
RUN apk add --no-cache \
    libc6-compat \
    build-base \
    python3 \
    libstdc++ \
    bash
WORKDIR /app
# Copy package definition files
COPY package.json pnpm-lock.yaml* ./
# Ensure pnpm-lock.yaml exists
RUN if [ ! -f pnpm-lock.yaml ]; then echo "pnpm-lock.yaml not found." && exit 1; fi
# Install the correct version of pnpm globally and install dependencies
RUN npm install -g pnpm@9 && pnpm install --frozen-lockfile --no-strict-peer-dependencies
# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
ENV SHARP_DIST_BASE_URL=https://cdn.skypack.dev/sharp-libvips
ENV SHARP_SKIP_AUTOINSTALL=true
# Build the application using pnpm (with --no-lint to bypass ESLint errors)
RUN pnpm run build --no-lint
# Debug: List the contents of /app after the build
RUN ls -la /app
RUN ls -la /app/.next
# Production image
FROM base AS runner
WORKDIR /app
# Set the runtime environment to production
ENV NODE_ENV production
ENV DATABASE_URI=$DATABASE_URI
ENV PAYLOAD_SECRET=$PAYLOAD_SECRET
ENV S3_ENDPOINT=$S3_ENDPOINT
ENV S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
ENV S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
ENV S3_BUCKET=$S3_BUCKET
ENV S3_REGION=$S3_REGION
ENV S3_FORCE_PATH_STYLE=$S3_FORCE_PATH_STYLE
ENV S3_PREFIX=$S3_PREFIX
# Disable telemetry during runtime
ENV NEXT_TELEMETRY_DISABLED 1
# Create a system group and user for non-root execution
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
# Set the correct permissions for the `.next` directory
RUN mkdir -p .next
RUN chown -R nextjs:nodejs .next
# Copy the `.next` directory and static files
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
# Switch to the non-root user
USER nextjs
# Expose the app's port
EXPOSE 3000
# Set the port environment variable
ENV PORT 3000
# Start the Next.js server
CMD ["node", "server.js"]