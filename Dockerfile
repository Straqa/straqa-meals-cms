# # Base image
# FROM node:22.12.0-alpine AS base

# # Install dependencies only when needed
# FROM base AS deps

# # Check https://github.com/nodejs/docker-node/tree/b4117f9333da4138b03a546ec926ef50a31506c3#nodealpine to understand why libc6-compat might be needed.
# RUN apk add --no-cache libc6-compat

# WORKDIR /app

# # Install dependencies based on the preferred package manager
# COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
# RUN \
#   if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
#   elif [ -f package-lock.json ]; then npm ci; \
#   elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm i --frozen-lockfile; \
#   else echo "Lockfile not found." && exit 1; \
#   fi

# # Rebuild the source code only when needed
# FROM base AS builder

# WORKDIR /app

# # Copy node_modules from the deps stage
# COPY --from=deps /app/node_modules ./node_modules

# # Copy the application source code
# COPY . .

# # Define build-time arguments (e.g., API keys, environment URLs, etc.)
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

# # Next.js collects completely anonymous telemetry data about general usage.
# # Learn more here: https://nextjs.org/telemetry
# # Uncomment the following line in case you want to disable telemetry during the build.
# # ENV NEXT_TELEMETRY_DISABLED 1

# # Run the build command based on the lockfile
# RUN \
#   if [ -f yarn.lock ]; then yarn run build; \
#   elif [ -f package-lock.json ]; then npm run build; \
#   elif [ -f pnpm-lock.yaml ]; then corepack enable pnpm && pnpm run build; \
#   else echo "Lockfile not found." && exit 1; \
#   fi

# # Production image, copy all the files and run next
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

# # Uncomment the following line in case you want to disable telemetry during runtime.
# # ENV NEXT_TELEMETRY_DISABLED 1

# # Create a system group and user for non-root execution
# RUN addgroup --system --gid 1001 nodejs
# RUN adduser --system --uid 1001 nextjs

# # Copy public assets if they exist
# # Remove this line if you do not have the `public` folder
# COPY --from=builder /app/public ./public

# # Set the correct permissions for the `.next` directory
# RUN mkdir .next
# RUN chown nextjs:nodejs .next

# # Automatically leverage output traces to reduce image size
# # https://nextjs.org/docs/advanced-features/output-file-tracing
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




# =========================
# BASE IMAGE
# =========================
FROM node:22.12.0-alpine AS base

# Install libc6-compat for compatibility and manually install PNPM
RUN apk add --no-cache libc6-compat curl \
    && npm install -g pnpm

# =========================
# DEPENDENCIES STAGE
# =========================
FROM base AS deps

WORKDIR /app

# Copy package.json and lock files for dependency installation
COPY package.json pnpm-lock.yaml ./

# Install all dependencies
RUN pnpm install --frozen-lockfile

# =========================
# BUILD STAGE
# =========================
FROM base AS builder

WORKDIR /app

# Copy node_modules from the deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy the application source code
COPY . .

# Define build-time arguments (e.g., API keys, environment URLs, etc.)
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

# Run the build command
RUN pnpm run build

# =========================
# FINAL PRODUCTION IMAGE
# =========================
FROM node:22.12.0-alpine AS runner

# Install libc6-compat for compatibility and manually install PNPM
RUN apk add --no-cache libc6-compat curl \
    && npm install -g pnpm

WORKDIR /app

# Set runtime environment variables
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

# Create and use a non-root user for security
RUN addgroup --system --gid 1001 nodejs \
    && adduser --system --uid 1001 nextjs

# Copy public and build artifacts from the builder stage
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./ 
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# Change to the non-root user
USER nextjs

# Expose the app's port
EXPOSE 3000

# Set environment variables (runtime)
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# Start the Next.js server
CMD ["node", "server.js"]