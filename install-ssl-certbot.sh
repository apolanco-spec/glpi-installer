#!/bin/bash
set -e

echo "======================================="
echo "🔐 Instalador SSL Let's Encrypt"
echo "Apache | Ubuntu 20.04 / 22.04"
echo "======================================="

read -p "👉 Ingresa el dominio (ej: soporte.midominio.com): " DOMAIN
read -p "📧 Ingresa un correo para Let's Encrypt: " EMAIL

if [[ -z "$DOMAIN" || -z "$EMAIL" ]]; then
  echo "❌ Dominio y correo son obligatorios"
  exit 1
fi

echo "[1/5] Instalando Certbot..."
apt update -y
apt install -y certbot python3-certbot-apache

echo "[2/5] Verificando Apache..."
systemctl is-active --quiet apache2 || {
  echo "❌ Apache no está activo"
  exit 1
}

echo "[3/5] Solicitando certificado SSL para $DOMAIN..."
certbot --apache \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  -m "$EMAIL" \
  --redirect

echo "[4/5] Habilitando renovación automática..."
systemctl enable certbot.timer
systemctl start certbot.timer

echo "[5/5] Verificación final..."
certbot certificates | grep "$DOMAIN" || {
  echo "⚠️ Certificado no encontrado"
  exit 1
}

echo "======================================="
echo "✅ SSL INSTALADO CORRECTAMENTE"
echo "🌐 https://$DOMAIN"
echo "🔁 Renovación automática habilitada"
echo "======================================="
