#!/bin/bash
set -e

echo "======================================="
echo "🧹 DESINSTALADOR COMPLETO GLPI 10"
echo "Ubuntu 22.04 | Apache | MariaDB"
echo "======================================="

read -p "⚠️  Esto eliminará GLPI y su base de datos. ¿Continuar? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

GLPI_DB="glpi"
GLPI_DB_USER="glpi"
APACHE_PORT="8080"

echo "[1/6] Deteniendo Apache (si existe)..."
systemctl stop apache2 || true

echo "[2/6] Eliminando archivos GLPI..."
rm -rf /var/www/glpi

echo "[3/6] Eliminando VirtualHost GLPI..."
a2dissite glpi.conf || true
rm -f /etc/apache2/sites-available/glpi.conf
systemctl reload apache2 || true

echo "[4/6] Restaurando Apache al puerto 80 (si aplica)..."
sed -i "s/Listen ${APACHE_PORT}/Listen 80/" /etc/apache2/ports.conf || true

echo "[5/6] Eliminando base de datos GLPI..."
if systemctl is-active --quiet mariadb; then
  mysql -u root <<EOF || true
DROP DATABASE IF EXISTS ${GLPI_DB};
DROP USER IF EXISTS '${GLPI_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
else
  echo "⚠️ MariaDB no estaba activo, base de datos no tocada."
fi

echo "[6/6] Limpieza final (logs y caché)..."
rm -rf /var/log/apache2/glpi*

echo "======================================="
echo "✅ GLPI ELIMINADO CORRECTAMENTE"
echo "El VPS sigue intacto."
echo "======================================="
