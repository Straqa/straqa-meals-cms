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
# Install pnpm in the builder stage
RUN npm install -g pnpm@9
# Copy node_modules from the deps stage
COPY --from=deps /app/node_modules ./node_modules
# Copy the application source code
COPY . .
# Debug: List files in /app
RUN ls -l /app
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
ENV S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
ENV S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
ENV S3_BUCKET=$S3_BUCKET
ENV S3_REGION=$S3_REGION
ENV S3_FORCE_PATH_STYLE=$S3_FORCE_PATH_STYLE
ENV S3_PREFIX=$S3_PREFIX
ENV SHARP_SKIP_AUTOINSTALL=true
# Build the application using pnpm (with --no-lint to bypass ESLint errors)
RUN pnpm run build --no-lint

# Production image
FROM base AS runner
WORKDIR /app
# Install pnpm globally in the production image
RUN npm install -g pnpm@9
# Copy the package.json file
COPY package.json pnpm-lock.yaml* ./
# Debug: List files in /app
RUN ls -l /app
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
ENV NEXT_TELEMETRY_DISABLED 1
# Set NODE_OPTIONS directly
ENV NODE_OPTIONS=--no-deprecation
# Create a system group and user for non-root execution
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs
# Set the correct permissions for the `.next` directory
RUN mkdir -p .next
RUN chown -R nextjs:nodejs .next
# Copy the `.next` directory and static files
COPY --from=builder --chown=nextjs:nodejs /app/.next ./.next
# Copy node_modules from the builder stage
COPY --from=builder --chown=nextjs:nodejs /app/node_modules ./node_modules
# Switch to the non-root user
USER nextjs
# Expose the app's port
EXPOSE 3000
# Set the port environment variable
ENV PORT 3000
# Start the Next.js server
CMD ["pnpm", "run", "start"]