# ---------------------------------------------------------------
# NEW STRATEGY: Build on GitHub, just serve here.
# We do NOT run 'flutter build' here anymore.
# ---------------------------------------------------------------

FROM nginx:alpine

# 1. Copy the pre-built web files
# These files are uploaded by the GitHub Action (Step 4 in deploy.yml)
# directly into the build/web folder on the server.
COPY ./build/web /usr/share/nginx/html

# 2. Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# 3. Health check
RUN apk add --no-cache curl
HEALTHCHECK --interval=10s --timeout=5s --retries=12 \
  CMD curl -fsS http://127.0.0.1:80/healthz || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]