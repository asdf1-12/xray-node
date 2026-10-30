FROM alpine:3.21

# Build-time steps are unrestricted: fetch the latest Xray core release.
RUN apk add --no-cache ca-certificates curl unzip \
 && mkdir -p /app /www \
 && curl -fsSL -o /tmp/xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip \
 && unzip -o /tmp/xray.zip -d /app \
 && rm -f /tmp/xray.zip \
 && echo ok > /www/index.html \
 && chmod +x /app/xray

# Runtime constraints: non-root (UID 1000), read-only root FS, ports >= 1024.
COPY --chown=1000:1000 entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

USER 1000
EXPOSE 8080
CMD ["/app/entrypoint.sh"]
