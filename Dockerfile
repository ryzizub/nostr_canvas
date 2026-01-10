# Stage 1: Build Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy source code
COPY . .

# Get dependencies
RUN flutter pub get

# Build web release
RUN flutter build web --release

# Stage 2: Serve with nginx
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Create non-root user and set permissions
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup && \
    chown -R appuser:appgroup /usr/share/nginx/html && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/log/nginx && \
    touch /tmp/nginx.pid && \
    chown appuser:appgroup /tmp/nginx.pid

# Run as non-root user
USER appuser

# Expose port 8080 (non-privileged)
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
