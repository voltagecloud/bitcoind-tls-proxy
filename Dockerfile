FROM debian:bookworm-slim

# Install stunnel and haproxy
RUN apt-get update && apt-get install -y \
    ca-certificates \
    stunnel4 \
    haproxy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose the local port
EXPOSE 8332 18332 18443 28332 38332

ENTRYPOINT ["/entrypoint.sh"]
