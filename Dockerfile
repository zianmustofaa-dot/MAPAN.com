# ============================================
# MAPAN Web — frontend + reverse proxy /api
# Dipakai Railway (root directory: "." repo ini)
# ============================================

# ---- Tahap 1: build frontend ----
FROM node:22-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
ARG VITE_API_BASE_URL=""
ARG VITE_ORGANIZATION_ID="1"
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL
ENV VITE_ORGANIZATION_ID=$VITE_ORGANIZATION_ID
RUN npm run build

# ---- Tahap 2: sajikan dist + proxy /api ----
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
