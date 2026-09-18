---
name: laravel-deploy
description: >
  Déploiement et infrastructure pour Laravel 13. Docker, CI/CD, Forge, Vapor,
  Coolify, Nginx. Utiliser quand on déploie une app, on configure Docker,
  on met en place le CI/CD, ou on configure le serveur.
license: MIT
compatibility: "Claude Code, Codex, OpenCode, Pi, omp"
allowed-tools: Read Write Glob Grep Bash
user-invocable: true
---

# Laravel Deploy — Déploiement Laravel 13

Tu es un expert en déploiement Laravel 13. Ton rôle est de guider le
déploiement sécurisé et efficace des applications Laravel.

## Quand utiliser

- Déployer une application Laravel
- Configurer Docker
- Mettre en place le CI/CD
- Configurer le serveur (Nginx, Apache)
- Optimiser pour la production

## Docker

### Dockerfile optimisé

```dockerfile
# Build stage
FROM php:8.3-fpm AS builder

WORKDIR /var/www

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-scripts

COPY . .
RUN php artisan config:cache && \
    php artisan route:cache && \
    php artisan view:cache

# Production stage
FROM php:8.3-fpm

WORKDIR /var/www

COPY --from=builder /var/www /var/www

RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000

CMD ["php-fpm"]
```

### docker-compose.yml

```yaml
version: '3.8'

services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - .:/var/www
    depends_on:
      - db
      - redis
    environment:
      - DB_CONNECTION=mysql
      - DB_HOST=db
      - DB_DATABASE=laravel
      - DB_USERNAME=laravel
      - DB_PASSWORD=secret

  db:
    image: mysql:8.0
    environment:
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: laravel
      MYSQL_USER: laravel
      MYSQL_PASSWORD: secret
    volumes:
      - db_data:/var/lib/mysql

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - .:/var/www
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
    depends_on:
      - app

  redis:
    image: redis:alpine

volumes:
  db_data:
```

## CI/CD

### GitHub Actions

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: mbstring, xml, ctype, json, bcmath, pdo, sqlite
          coverage: none

      - name: Install Dependencies
        run: composer install --no-progress --prefer-dist

      - name: Copy Environment File
        run: cp .env.testing .env

      - name: Generate App Key
        run: php artisan key:generate

      - name: Run Migrations
        run: php artisan migrate --force

      - name: Run Tests
        run: php artisan test

      - name: Run PHPStan
        run: vendor/bin/phpstan analyse

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'

    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Production
        run: |
          # Déploiement selon la plateforme
          echo "Deploying..."
```

## Nginx

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/public;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    index index.php;

    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    error_page 404 /index.php;

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.3-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
```

## Optimisation production

```bash
# Cache everything
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache

# Optimiser l'autoloader
composer install --optimize-autoloader --no-dev

# Vérifier la config
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

## Health check

```php
// routes/web.php
Route::get('/health', function () {
    try {
        DB::connection()->getPdo();
        Cache::get('test');
        return response('OK', 200);
    } catch (\Exception $e) {
        return response('ERROR', 500);
    }
});
```

## Bonnes pratiques

1. **Multi-stage Docker build** — Réduire la taille de l'image
2. **Variables d'env jamais dans les images** — Utiliser `.env` ou des secrets
3. **Health checks** — Pour le monitoring et le load balancer
4. **Zero-downtime deployment** — Rolling updates ou blue-green
5. **Cache en production** — Config, routes, views
6. **Logging structuré** — Pour le debugging en production
7. **Monitoring** — Pulse, Telescope, ou outils externes
8. **Backup automatique** — Base de données et storage
9. **SSL/TLS** — Let's Encrypt ou certificat managé
10. **Supervisor pour les workers** — Queue workers en production

## Validation

- [ ] Docker build passe
- [ ] CI/CD configuré et fonctionnel
- [ ] Nginx configuré correctement
- [ ] Health check répond
- [ ] SSL configuré
- [ ] Logs configurés
- [ ] Backup automatique
