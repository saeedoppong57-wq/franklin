#!/usr/bin/env bash
# ===========================================================================
# Fix nginx "mkdir() /var/lib/nginx/proxy_temp failed (13: Permission denied)"
# This happens when nginx cannot write to its temp/cache/log dirs. The fix is
# to make those dirs owned by the same user the nginx WORKER runs as.
# ===========================================================================

set -euo pipefail

# Detect the nginx user (default www-data on Debian/Ubuntu, nginx on RHEL)
NGINX_USER="$(ps -o user= -C nginx 2>/dev/null | head -n1 | tr -d ' ')"
if [ -z "$NGINX_USER" ]; then
    if id www-data >/dev/null 2>&1; then NGINX_USER="www-data";
    elif id nginx   >/dev/null 2>&1; then NGINX_USER="nginx";
    else echo "Could not detect nginx user"; exit 1; fi
fi
echo "Using nginx user: $NGINX_USER"

# 1) Fix the temp/cache/log directories nginx uses at runtime.
#    This is the line from your example, expanded to the whole nginx dir.
for d in /var/lib/nginx /var/log/nginx /var/cache/nginx /var/run/nginx; do
    if [ -d "$d" ]; then
        mkdir -p "$d"
        chown -R "${NGINX_USER}:${NGINX_USER}" "$d"
    fi
done

# 2) Make sure the web root is readable by nginx.
WEB_ROOT="${1:-/var/www/franklin}"
if [ -d "$WEB_ROOT" ]; then
    chown -R "${NGINX_USER}:${NGINX_USER}" "$WEB_ROOT"
    chmod -R 755 "$WEB_ROOT"
fi

# 3) Ensure nginx.conf has the right user line (Debian uses www-data).
if grep -q "^user" /etc/nginx/nginx.conf; then
    sed -i "s/^user .*/user ${NGINX_USER};/" /etc/nginx/nginx.conf
else
    sed -i "1i user ${NGINX_USER};" /etc/nginx/nginx.conf
fi

echo "Done. Run:  nginx -t && systemctl reload nginx"
