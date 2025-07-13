# Perry Chick Frontend Dockerfile
FROM node:18-alpine AS base
WORKDIR /app

# Install dependencies
FROM base AS deps
COPY package*.json ./
RUN npm ci --omit=dev

# Build the application
FROM base AS build
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production image - Run Node.js server
FROM node:18-alpine AS runtime
WORKDIR /app

# Copy built application and dependencies
COPY --from=build /app/build ./build
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./

EXPOSE 3000

# Set NODE_ENV to production
ENV NODE_ENV=production
ENV HOST=0.0.0.0
ENV PORT=3000

# Start the SvelteKit server
CMD ["npm", "start"]
