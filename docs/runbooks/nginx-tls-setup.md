# Nginx + TLS setup runbook (production host)

This walks an operator through bringing the host nginx up with TLS in front of
the Docker stack. Do this **once** when provisioning the server; the rest is
automatic.

## Prereqs on the host
- Ubuntu 22.04 / Debian 12 (any current LTS works)
- Public DNS `A` records for `strotech.uz` and `www.strotech.uz` pointing at
  the server's public IP
- Ports 80 and 443 open in the firewall (nginx will bind both)
- Docker stack from this repo running on `127.0.0.1:8080` (API) and
  `127.0.0.1:8081` (Flutter)

## 1. Install nginx + certbot

```bash
sudo apt update
sudo apt install -y nginx certbot python3-certbot-nginx
```

## 2. Drop in the repo's nginx config

```bash
sudo install -m 644 -o root -g root \
    deployment/nginx/strotech.uz.conf \
    /etc/nginx/sites-available/strotech.uz.conf

sudo mkdir -p /etc/nginx/snippets
sudo install -m 644 -o root -g root \
    deployment/nginx/strotech-proxy.conf \
    /etc/nginx/snippets/strotech-proxy.conf

sudo ln -sf /etc/nginx/sites-available/strotech.uz.conf /etc/nginx/sites-enabled/strotech.uz.conf
sudo rm -f /etc/nginx/sites-enabled/default
```

## 3. Temporarily comment out the HTTPS server block

Certbot needs port 80 reachable to complete the ACME http-01 challenge, and the
HTTPS server block references certificate files that don't exist yet. Comment
out the entire `server { listen 443 ssl http2; ... }` block, save, then:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

## 4. Issue the certificate

```bash
sudo certbot --nginx \
    -d strotech.uz \
    -d www.strotech.uz \
    --redirect \
    --agree-tos -m ops@strotech.uz
```

Certbot drops the certificate at `/etc/letsencrypt/live/strotech.uz/`.

## 5. Restore the HTTPS server block

Uncomment the HTTPS block you commented in step 3, then:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

## 6. Verify

```bash
# Should 301 to https
curl -I http://strotech.uz/

# Should return the API health JSON
curl https://strotech.uz/health

# HSTS header should be present
curl -I https://strotech.uz/ | grep -i strict-transport
```

## 7. Auto-renewal

Certbot installs a systemd timer that renews twice a day. Verify it's active:

```bash
sudo systemctl list-timers | grep certbot
sudo certbot renew --dry-run
```

## Common failures

| Symptom | Cause | Fix |
|---|---|---|
| `nginx: [emerg] cannot load certificate` after step 2 | HTTPS block references certs that don't exist yet | Step 3 — comment HTTPS block first |
| `Connection refused` from `/api/...` | Docker API container down or bound to wrong host | `docker compose ps`; `docker compose logs market-system-api` |
| Browsers show "Not Secure" after step 5 | Mixed-content from old HTTP image URLs cached | Hard refresh; verify `Strict-Transport-Security` header is set |
| `429 Too Many Requests` on legitimate clients | nginx `limit_req` zones too tight | Tune `rate=` in `deployment/nginx/strotech.uz.conf` |
