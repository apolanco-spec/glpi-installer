#!/bin/bash
set -e

echo "======================================="
echo "🧹 DESINSTALADOR COMPLETO GLPI 10"
echo "Ubuntu 22.04 | Apache | MariaDB"
echo "======================================="

read -p "⚠️  Esto ELIMINARÁ GLPI y su base de datos. ¿Continuar? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "❌ Operación cancelada."
  exit 1
fi

GLPI_DB="glpi"
GLPI_DB_USER="glpi"
APACHE_PORT="8080"

echo "[1/7] Deteniendo servicios..."
systemctl stop apache2 mariadb || true

echo "[2/7] Eliminando archivos GLPI..."
rm -rf /var/www/glpi

echo "[3/7] Eliminando configuración Apache..."
a2dissite glpi.conf || true
rm -f /etc/apache2/sites-available/glpi.conf
systemctl reload apache2 || true

echo "[4/7] Restaurando Apache (puerto por defecto si aplica)..."
sed -i "s/Listen ${APACHE_PORT}/Listen 80/" /etc/apache2/ports.conf || true

echo "[5/7] Eliminando base de datos y usuario..."
mysql <<EOF
DROP DATABASE IF EXISTS ${GLPI_DB};
DROP USER IF EXISTS '${GLPI_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "[6/7] Eliminando dependencias (opcional)..."
apt remove -y apache2 mariadb-server php php-* || true
apt autoremove -y || true

echo "[7/7] Limpieza final..."
rm -rf /etc/apache2 /etc/php /etc/mysql
rm -rf /var/lib/mysql

echo "======================================="
echo "✅ GLPI ELIMINADO COMPLETAMENTE"
echo "El sistema quedó limpio."
echo "======================================="
