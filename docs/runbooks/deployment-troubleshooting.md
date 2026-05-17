# MarketSystem Deployment Fix

## Muammolar:
1. Nginx 500 Internal Server Error
2. Flutter Client bog'lanish muammosi
3. CORS muammosi

## Hal qilish qadamlari:

### 1. API va Frontendni qayta deploy qilish:

```bash
# Serverga ulaning
ssh user@114.29.239.156

# Docker containerlarni yangilash
cd /path/to/MarketSystem
git pull origin master

# API va Frontendni rebuild qilish
docker-compose down
docker-compose up -d --build

# Containerlar holatini tekshirish
docker ps
docker logs market-system-api
docker logs market-system-client
```

### 2. Nginx konfiguratsiyasini yangilash:

```bash
# Yangi nginx konfiguratsiyasini nusxalash
sudo cp /path/to/nginx.conf /etc/nginx/sites-available/strotech.uz

# Test qilish
sudo nginx -t

# Nginxni qayta yuklash
sudo systemctl reload nginx

# Nginx statusini tekshirish
sudo systemctl status nginx

# Nginx loglarini tekshirish
sudo tail -f /var/log/nginx/strotech.uz.error.log
sudo tail -f /var/log/nginx/strotech.uz.access.log
```

### 3. Flutter Web Build qilish:

```bash
# Frontend containerini to'g'ri build qilish
docker-compose build market-system-client
docker-compose up -d market-system-client

# Frontend build natijasini tekshirish
docker exec -it market-system-client ls -la /usr/share/nginx/html/
```

### 4. API endpointlarini test qilish:

```bash
# Health check
curl http://114.29.239.156:8080/health

# Swagger tekshirish
curl http://114.29.239.156:8080/swagger/index.html

# CORS test
curl -X OPTIONS http://114.29.239.156:8080/api/Auth/Login \
  -H "Origin: https://strotech.uz" \
  -H "Access-Control-Request-Method: POST" \
  -v
```

### 5. Frontend URL test qilish:

```bash
# Nginx orqali frontend test
curl http://114.29.239.156/

# API proxy test
curl http://114.29.239.156/api/health

# SignalR proxy test
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Key: test" \
  -H "Sec-WebSocket-Version: 13" \
  http://114.29.239.156/hubs/sales
```

## Debug qilish:

### Docker containerlar holati:
```bash
# Barcha containerlarni ko'rish
docker ps -a

# API logs
docker logs -f market-system-api

# Client logs
docker logs -f market-system-client

# Database logs
docker logs -f market-system-db
```

### Nginx debug:
```bash
# Nginx konfiguratsiyasi test
sudo nginx -t

# Nginx reload
sudo systemctl reload nginx

# Nginx logs
sudo tail -f /var/log/nginx/strotech.uz.error.log
```

### Browser debug:
1. Chrome Developer Tools oching
2. Network tabni tekshiring
3. Console loglarni ko'ring
4. CORS headersni tekshiring

## Odatiy muammolar va yechimlari:

### 1. "Connection refused" error:
- Docker containerlar ishlamasligi mumkin
- Portlar to'g'ri ochilmagan bo'lishi mumkin
- Firewall muammosi bo'lishi mumkin

Yechim:
```bash
# Containerlar holatini tekshirish
docker ps

# Portlarni tekshirish
netstat -tulpn | grep -E '80|8080|8081'

# Firewall tekshirish
sudo ufw status
```

### 2. CORS error:
- Origin noto'g'ri bo'lishi mumkin
- API CORS siyosati noto'g'ri bo'lishi mumkin

Yechim:
- CORS headersni tekshirish
- Origin URLni to'g'rilash

### 3. 500 Internal Server Error:
- Nginx upstream ulanish muammosi
- Containerlar ishlamasligi

Yechim:
- Nginx logsni tekshirish
- Docker logsni tekshirish
- Containerlarni qayta start qilish

## Muvaffaqiyatli deployment belgilari:

✅ API health check: `{"status":"healthy","database":"connected"}`
✅ Swagger accessible: http://114.29.239.156:8080/swagger/index.html
✅ Frontend accessible: http://114.29.239.156/
✅ Nginx logs: error bo'lmasligi kerak
✅ Docker containers: barchasi "Up" statusida bo'lishi kerak
