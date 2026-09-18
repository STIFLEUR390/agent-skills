# Guide d'utilisation — laravel-deploy

Déploiement et infrastructure Laravel 13.

---

## Quand l'utiliser

- Déployer une application
- Configurer Docker
- Mettre en place le CI/CD
- Configurer Nginx

---

## Exemple 1 — Dockerfile rapide

**Demander** :
```
Crée un Dockerfile optimisé pour ce projet.
```

**Le skill génère** :

```dockerfile
FROM php:8.3-fpm AS builder
WORKDIR /var/www
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader
COPY . .
RUN php artisan config:cache && php artisan route:cache

FROM php:8.3-fpm
COPY --from=builder /var/www /var/www
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache
EXPOSE 9000
CMD ["php-fpm"]
```

---

## Exemple 2 — GitHub Actions CI

**Demander** :
```
Configure le CI avec GitHub Actions pour les tests.
```

**Le skill génère** :

```yaml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
      - run: composer install --no-progress
      - run: php artisan test
```

---

## Voir aussi

- `laravel-core` — Fondamentaux
- `laravel-security` — Sécurité en production
