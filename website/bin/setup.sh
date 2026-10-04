#!/usr/bin/env bash
# Start the HandLive website (nginx + PHP-FPM + MariaDB) and seed it. Safe to rerun: WordPress is installed
# once, then pages and posts are updated in place from seed/content.
#   website/bin/setup.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  cp .env.example .env
  for key in DB_PASSWORD DB_ROOT_PASSWORD ADMIN_PASSWORD; do
    value=$(openssl rand -base64 32 | tr -dc 'A-Za-z0-9' | head -c 24)
    sed -i.bak "s/^${key}=generate$/${key}=${value}/" .env
  done
  rm -f .env.bak
  echo "Created website/.env with random passwords (git-ignored)."
fi
set -a
. ./.env
set +a

wp() { docker compose --progress quiet run --rm -T wpcli wp "$@"; }

# nginx starts only once WordPress is installed, so its web installer is never reachable (nginx also denies it).
docker compose --progress quiet up -d db php
printf 'Waiting for WordPress files'
until docker compose exec -T php test -f /var/www/html/wp-includes/version.php 2>/dev/null; do printf '.'; sleep 2; done
echo

if ! wp core is-installed >/dev/null 2>&1; then
  wp core install --url="$SITE_URL" --title="HandLive" --admin_user="$ADMIN_USER" \
    --admin_password="$ADMIN_PASSWORD" --admin_email="$ADMIN_EMAIL" --skip-email
fi
docker compose --progress quiet up -d
wp rewrite structure '/%postname%/' --quiet
wp plugin is-installed polylang || wp plugin install polylang
wp plugin activate polylang --quiet
wp plugin auto-updates enable polylang --quiet 2>/dev/null || true
wp theme activate handlive --quiet
# Nothing else runs on this site: drop the bundled extras.
wp plugin delete hello akismet --quiet 2>/dev/null || true

python3 bin/build_privacy_content.py
wp eval-file /seed/seed.php --user="$ADMIN_USER"
wp rewrite flush --quiet

echo "HandLive website: $SITE_URL  (admin: $SITE_URL/wp-admin/, user $ADMIN_USER, password in website/.env)"
