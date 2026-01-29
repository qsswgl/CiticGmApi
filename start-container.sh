#!/bin/bash
docker run -d \
  --name abc-payment-gateway \
  --restart unless-stopped \
  --network traefik-net \
  -v /opt/abc-payment/logs:/app/logs \
  -v /opt/cert:/app/cert:ro \
  -v /opt/Wechat/cert:/app/Wechat/cert:ro \
  -e ASPNETCORE_ENVIRONMENT=Production \
  -e ASPNETCORE_URLS=http://+:8080 \
  -e TZ=Asia/Shanghai \
  --label traefik.enable=true \
  --label 'traefik.http.routers.payment.rule=Host(`payment.qsgl.net`)' \
  --label traefik.http.routers.payment.entrypoints=websecure \
  --label traefik.http.routers.payment.tls=true \
  --label traefik.http.services.payment.loadbalancer.server.port=8080 \
  --label traefik.docker.network=traefik-net \
  --label traefik.http.services.payment.loadbalancer.healthcheck.path=/health \
  --label traefik.http.services.payment.loadbalancer.healthcheck.interval=30s \
  --label 'traefik.http.routers.payment-http.rule=Host(`payment.qsgl.net`)' \
  --label traefik.http.routers.payment-http.entrypoints=web \
  --label traefik.http.routers.payment-http.middlewares=redirect-to-https \
  --label traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https \
  --label traefik.http.middlewares.redirect-to-https.redirectscheme.permanent=true \
  abc-payment-gateway:latest

echo "Container started successfully"
docker ps --filter name=abc-payment-gateway
