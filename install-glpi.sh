#!/bin/bash
set -e

echo "======================================="
echo "🚀 INSTALADOR AUTOMÁTICO GLPI 10"
echo "Ubuntu 22.04 | Apache | PHP 8.1 | 8080"
echo "======================================="

GLPI_VERSION="10.0.13"
GLPI_DB="glpi"
GLPI_DB_USER="glpi"
GLPI_DB_PASS="GLPI@2026Segura!"
APACHE_PORT="8080"

echo "[1/8] Actualizando sistema..."
apt update -y && apt upgrade -y

echo "[2/8] Instalando dependencias..."
apt install -y apache2 mariadb-server wget tar unzip \
php php-cli php-mysql php-gd php-intl php-mbstring php-xml php-curl php-zip php-bcmath

echo "[3/8] Configurando Apache en puerto 8080..."
sed -i "s/Listen 80/Listen ${APACHE_PORT}/" /etc/apache2/ports.conf

cat <<EOF >/etc/apache2/sites-available/glpi.conf
<VirtualHost *:${APACHE_PORT}>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/glpi

    <Directory /var/www/glpi>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF

a2dissite 000-default.conf || true
a2ensite glpi.conf
a2enmod rewrite
systemctl restart apache2

echo "[4/8] Descargando GLPI..."
cd /tmp
wget https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz
tar -xzf glpi-${GLPI_VERSION}.tgz -C /var/www/

chown -R www-data:www-data /var/www/glpi
find /var/www/glpi -type d -exec chmod 755 {} \;
find /var/www/glpi -type f -exec chmod 644 {} \;

echo "[5/8] Configurando MariaDB..."
mysql <<EOF
DROP DATABASE IF EXISTS ${GLPI_DB};
DROP USER IF EXISTS '${GLPI_DB_USER}'@'localhost';
CREATE DATABASE ${GLPI_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${GLPI_DB_USER}'@'localhost' IDENTIFIED BY '${GLPI_DB_PASS}';
GRANT ALL PRIVILEGES ON ${GLPI_DB}.* TO '${GLPI_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

systemctl restart mariadb
systemctl restart apache2

IP=$(hostname -I | awk '{print $1}')

echo "======================================="
echo "✅ GLPI INSTALADO CORRECTAMENTE"
echo "URL: http://${IP}:${APACHE_PORT}"
echo "Usuario admin: glpi | Password: glpi"
echo "======================================="
