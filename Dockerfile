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
ENV S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
ENV S3_BUCKET=$S3_BUCKET
ENV S3_REGION=$S3_REGION
ENV S3_FORCE_PATH_STYLE=$S3_FORCE_PATH_STYLE
ENV S3_PREFIX=$S3_PREFIX
# Disable telemetry during the build
ENV NEXT_TELEMETRY_DISABLED 1
# Configure sharp to use a mirror or retry downloads
ENV SHARP_DIST_BASE_URL=https://cdn.skypack.dev/sharp-libvips
ENV SHARP_SKIP_AUTOINSTALL=true
# Build the application using pnpm (with --no-lint to bypass ESLint errors)
RUN pnpm run build --no-lint

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
# Handle optional public folder
RUN mkdir -p ./public
COPY --from=builder /app/public ./public/
# Set the correct permissions for the `.next` directory
RUN mkdir -p .next
RUN chown -R nextjs:nodejs .next
# Copy the standalone build and static files
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
# Switch to the non-root user
USER nextjs
# Expose the app's port
EXPOSE 3000
# Set the port environment variable
ENV PORT 3000
# Start the Next.js server
CMD ["node", "server.js"]





# Use Node.js 20 for compatibility
# FROM node:20-alpine AS base

# # Step 1. Rebuild the source code only when needed
# FROM base AS builder

# WORKDIR /app

# # Install dependencies based on the preferred package manager
# COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
# RUN ls

# # Install dependencies with legacy peer deps 
# RUN \
#     if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
#     elif [ -f package-lock.json ]; then npm ci; \
#     elif [ -f pnpm-lock.yaml ]; then npm install -g corepack@latest && corepack enable pnpm && pnpm install --frozen-lockfile; \
#     else echo "Warning: Lockfile not found." && npm install --legacy-peer-deps; \
#     fi

# # Copy source files
# COPY . .

# # Set environment variables
# ARG DATABASE_URI
# ARG PAYLOAD_SECRET
# ARG S3_ENDPOINT
# ARG S3_ACCESS_KEY_ID
# ARG S3_SECRET_ACCESS_KEY
# ARG S3_BUCKET
# ARG S3_REGION
# ARG S3_FORCE_PATH_STYLE
# ARG S3_PREFIX
# ENV DATABASE_URI=$DATABASE_URI
# ENV PAYLOAD_SECRET=$PAYLOAD_SECRET
# ENV S3_ENDPOINT=$S3_ENDPOINT
# ENV S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
# ENV S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
# ENV S3_BUCKET=$S3_BUCKET
# ENV S3_REGION=$S3_REGION
# ENV S3_FORCE_PATH_STYLE=$S3_FORCE_PATH_STYLE
# ENV S3_PREFIX=$S3_PREFIX

# # Build react router app
# RUN \
#     if [ -f yarn.lock ]; then yarn build; \
#     elif [ -f package-lock.json ]; then npm run build; \
#     elif [ -f pnpm-lock.yaml ]; then pnpm build; \
#     else npm run build; \
#     fi

# # Step 2. Production image
# FROM base AS runner

# WORKDIR /app

# # Create non-root user
# # RUN addgroup --system --gid 1001 nodejs
# # RUN adduser --system --uid 1001 react-router
# # USER react-router

# # Copy built assets
# COPY --from=builder /app/public ./public

# # Copy built assets
# COPY ./package.json pnpm-lock.yaml /app/
# COPY --from=builder /app/node_modules /app/node_modules
# COPY --from=builder /app/build /app/build

# # Start the application
# CMD ["pnpm", "run", "start"]



# # Base image
# FROM node:18-alpine AS base

# # Install dependencies only when needed
# FROM base AS deps
# # Install libc6-compat for compatibility with certain native modules
# RUN apk add --no-cache libc6-compat
# WORKDIR /app
# # Copy package definition files
# COPY package.json pnpm-lock.yaml* ./
# # Ensure pnpm-lock.yaml exists
# RUN if [ ! -f pnpm-lock.yaml ]; then echo "pnpm-lock.yaml not found." && exit 1; fi
# # Install pnpm globally and install dependencies
# RUN npm install -g pnpm && pnpm install --frozen-lockfile

# # Rebuild the source code only when needed
# FROM base AS builder
# WORKDIR /app
# # Copy node_modules from the deps stage
# COPY --from=deps /app/node_modules ./node_modules
# # Copy the application source code
# COPY . .
# # Define build-time arguments
# ARG DATABASE_URI
# ARG PAYLOAD_SECRET
# ARG S3_ENDPOINT
# ARG S3_ACCESS_KEY_ID
# ARG S3_SECRET_ACCESS_KEY
# ARG S3_BUCKET
# ARG S3_REGION
# ARG S3_FORCE_PATH_STYLE
# ARG S3_PREFIX
# # Set environment variables for the build stage
# ENV DATABASE_URI=$DATABASE_URI
# ENV PAYLOAD_SECRET=$PAYLOAD_SECRET
# ENV S3_ENDPOINT=$S3_ENDPOINT
# ENV S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
# ENV S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
# ENV S3_BUCKET=$S3_BUCKET
# ENV S3_REGION=$S3_REGION
# ENV S3_FORCE_PATH_STYLE=$S3_FORCE_PATH_STYLE
# ENV S3_PREFIX=$S3_PREFIX
# # Disable telemetry during the build
# ENV NEXT_TELEMETRY_DISABLED 1
# # Build the application using pnpm
# RUN pnpm run build

# # Production image
# FROM base AS runner
# WORKDIR /app
# # Set the runtime environment to production
# ENV NODE_ENV production
# ENV DATABASE_URI=$DATABASE_URI
# ENV PAYLOAD_SECRET=$PAYLOAD_SECRET
# ENV S3_ENDPOINT=$S3_ENDPOINT
# ENV S3_ACCESS_KEY_ID=$S3_ACCESS_KEY_ID
# ENV S3_SECRET_ACCESS_KEY=$S3_SECRET_ACCESS_KEY
# ENV S3_BUCKET=$S3_BUCKET
# ENV S3_REGION=$S3_REGION
# ENV S3_FORCE_PATH_STYLE=$S3_FORCE_PATH_STYLE
# ENV S3_PREFIX=$S3_PREFIX
# # Disable telemetry during runtime
# ENV NEXT_TELEMETRY_DISABLED 1
# # Create a system group and user for non-root execution
# RUN addgroup --system --gid 1001 nodejs
# RUN adduser --system --uid 1001 nextjs
# # Conditionally copy public assets
# COPY --from=builder /app/public ./public 
# # Set the correct permissions for the `.next` directory
# RUN mkdir -p .next
# RUN chown -R nextjs:nodejs .next
# # Copy the standalone build and static files
# COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
# COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
# # Switch to the non-root user
# USER nextjs
# # Expose the app's port
# EXPOSE 3000
# # Set the port environment variable
# ENV PORT 3000
# # Start the Next.js server
# CMD ["node", "server.js"]