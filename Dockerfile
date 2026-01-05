# Build stage - Flutter web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .

# Build arguments for API URLs
ARG B2C_API_URL=https://b2c.oguzforum.com
ARG TOURISM_API_URL=http://backend:8000

RUN flutter pub get && \
    flutter build web --release \
      --dart-define=B2C_API_URL=${B2C_API_URL} \
      --dart-define=TOURISM_API_URL=${TOURISM_API_URL}

# Production stage - Nginx
FROM nginx:alpine

# Copy built web app
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Health check
RUN apk add --no-cache curl
HEALTHCHECK --interval=10s --timeout=5s --retries=12 \
  CMD curl -fsS http://127.0.0.1:80/healthz || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
