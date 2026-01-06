#!/bin/bash
set -e

echo "======================================="
echo "🚀 INSTALADOR AUTOMÁTICO GLPI 10"
echo "Ubuntu 22.04 | Apache | PHP 8.1 | 8080"
echo "======================================="

# Variables
GLPI_VERSION="10.0.13"
GLPI_DB="glpi"
GLPI_DB_USER="glpi"
GLPI_DB_PASS="GLPI@2026Segura!"
APACHE_PORT="8080"

# -----------------------------
echo "[1/8] Actualizando sistema..."
# -----------------------------
apt update -y
apt upgrade -y

# -----------------------------
echo "[2/8] Instalando dependencias..."
# -----------------------------
apt install -y apache2 mariadb-server wget tar unzip \
php php-cli php-mysql php-gd php-intl php-mbstring php-xml php-curl php-zip php-bcmath

# -----------------------------
echo "[3/8] Configurando Apache de forma segura..."
# -----------------------------

# Limpiar listeners previos (evita duplicados)
sed -i '/^Listen 80$/d' /etc/apache2/ports.conf || true
sed -i '/^Listen 8080$/d' /etc/apache2/ports.conf || true

# Definir puerto único
echo "Listen ${APACHE_PORT}" >> /etc/apache2/ports.conf

# VirtualHost GLPI
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

apache2ctl configtest
systemctl restart apache2

# -----------------------------
echo "[4/8] Descargando GLPI..."
# -----------------------------
cd /tmp
rm -rf /var/www/glpi
wget -q https://github.com/glpi-project/glpi/releases/download/${GLPI_VERSION}/glpi-${GLPI_VERSION}.tgz
tar -xzf glpi-${GLPI_VERSION}.tgz -C /var/www/

chown -R www-data:www-data /var/www/glpi
find /var/www/glpi -type d -exec chmod 755 {} \;
find /var/www/glpi -type f -exec chmod 644 {} \;

# -----------------------------
echo "[5/8] Configurando MariaDB..."
# -----------------------------
systemctl start mariadb

mysql <<EOF
DROP DATABASE IF EXISTS ${GLPI_DB};
DROP USER IF EXISTS '${GLPI_DB_USER}'@'localhost';
CREATE DATABASE ${GLPI_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER '${GLPI_DB_USER}'@'localhost' IDENTIFIED BY '${GLPI_DB_PASS}';
GRANT ALL PRIVILEGES ON ${GLPI_DB}.* TO '${GLPI_DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# -----------------------------
echo "[6/8] Reiniciando servicios..."
# -----------------------------
systemctl restart mariadb
systemctl restart apache2

# -----------------------------
echo "[7/8] Firewall (si está activo)..."
# -----------------------------
ufw allow ${APACHE_PORT}/tcp || true

IP=$(hostname -I | awk '{print $1}')

# -----------------------------
echo "======================================="
echo "✅ GLPI INSTALADO CORRECTAMENTE"
echo "---------------------------------------"
echo "🌐 Acceso web:"
echo "   http://${IP}:${APACHE_PORT}"
echo
echo "🧑 Usuario administrador GLPI:"
echo "   Usuario: glpi"
echo "   Clave:   glpi"
echo
echo "🗄️ Base de datos MariaDB:"
echo "   Base:    ${GLPI_DB}"
echo "   Usuario: ${GLPI_DB_USER}"
echo "   Clave:   ${GLPI_DB_PASS}"
echo
echo "⚠️ CAMBIA TODAS LAS CONTRASEÑAS AL PRIMER ACCESO"
echo "======================================="
