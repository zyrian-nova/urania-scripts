#!/bin/bash

# Define el color
NC='\033[0m' # No Color
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'

# Actualiza el sistema
echo -e "${BLUE}Actualizando el sistema...${NC}"
sudo dnf update -y
echo -e "${GREEN}Actualización terminada...${NC}"

# Instala Git
echo -e "${BLUE}Instalando Git y otras herramientas...${NC}"
sudo dnf install git httpd openssl mod_ssl net-tools bind-utils traceroute vim rsyslog yum-utils dnf-utils util-linux-user wget zip unzip curl libxml2 -y
echo -e "${GREEN}Instalación terminada...${NC}"

# Desactiva SELinux
echo -e "${BLUE}Desactivando SELinux...${NC}"
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
echo -e "${GREEN}SELinux desactivado...${NC}"

# Instalación de PHP 8.3 desde el repositorio Remi
echo -e "${BLUE}Instalando PHP 8.3...${NC}"
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.2.rpm
sudo dnf module reset php -y
sudo dnf module install php:remi-8.3 -y
sudo dnf install php php-cli php-gd php-curl php-zip php-mbstring -y

# Instalación de Composer
echo -e "${BLUE}Instalando Composer...${NC}"
wget https://getcomposer.org/installer -O composer-installer.php
sudo php composer-installer.php --filename=composer --install-dir=/usr/local/bin

# Crear un enlace simbólico para Composer
echo -e "${GREEN}Creando enlace simbólico para Composer...${NC}"
sudo ln -s /usr/local/bin/composer /usr/bin/composer

# Instalación de Node.js
echo -e "${BLUE}Instalando Node.js...${NC}"
curl -sL https://rpm.nodesource.com/setup_18.x -o nodesource_setup.sh
sudo bash nodesource_setup.sh
sudo dnf install nodejs -y

# Instalación y configuración de MariaDB
echo -e "${BLUE}Instalando y configurando MariaDB...${NC}"
sudo dnf install mariadb-server -y
echo -e "${BLUE}Habilitando MariaDB...${NC}"
sudo systemctl enable mariadb
echo -e "${BLUE}Iniciando MariaDB...${NC}"
sudo systemctl start mariadb

# Ejecuta mysql_secure_installation
echo -e "${BLUE}Ejecutando mysql_secure_installation siga las instrucciones en pantalla (La contraseña por defecto de ROOT es solo dar ENTER)...${NC}"
sudo mysql_secure_installation

# Solicita al usuario que introduzca la contraseña del root de MariaDB
echo -e "${BLUE}Introduce la contraseña de root de MariaDB que seleccionaste previamente:${NC}"
read -s ROOT_PASSWORD
echo -e "${GREEN}¡Éxito!${NC}"

# Solicita al usuario que introduzca la contraseña del root de MariaDB
echo -e "${BLUE}Introduce la contraseña de que tendrá el usuario 'pma' para el manejo de PHP My Admin:${NC}"
read -s PMA_PASSWORD
echo -e "${GREEN}¡Éxito!${NC}"

# Solicita al usuario que introduzca la contraseña del root de Nextcloud
echo -e "${BLUE}Introduce la contraseña de que tendrá el usuario 'nextcloud_user' para el manejo de Nextcloud:${NC}"
read -s NXT_PASSWORD
echo -e "${GREEN}¡Éxito!${NC}"

# Verifica si el directorio Descargas existe, si no, lo crea
echo -e "${BLUE}Verificando el directorio de Descargas...${NC}"
if [ ! -d "$HOME/Descargas" ]; then
    mkdir -p "$HOME/Descargas"
    echo -e "${GREEN}Directorio creado...${NC}"
fi
echo -e "${GREEN}Directorio listo...${NC}"

# Cambia al directorio Descargas
cd "$HOME/Descargas"

# Descarga e instalación de Nextcloud
echo -e "${BLUE}Descargando Nextcloud...${NC}"
wget https://download.nextcloud.com/server/releases/latest.zip
unzip latest.zip
sudo mv nextcloud /var/www/nextcloud
sudo chown -R apache:apache /var/www/nextcloud
sudo chmod -R 755 /var/www/nextcloud

# Instalación de phpMyAdmin
echo -e "${BLUE}Instalando phpMyAdmin...${NC}"
sudo dnf install php php-pdo php-pecl-zip php-json php-mbstring php-bcmath php-pecl-mcrypt php-process php-mysqlnd -y
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
unzip phpMyAdmin-5.2.1-all-languages.zip
sudo mv phpMyAdmin-5.2.1-all-languages /usr/share/phpmyadmin
sudo mkdir /usr/share/phpmyadmin/tmp
sudo cp /usr/share/phpmyadmin/config.sample.inc.php /usr/share/phpmyadmin/config.inc.php
# Genera un secreto para el archivo de configuración
echo -e "${YELLOW}Generando blowfish secret...${NC}"
BLOWFISH_SECRET=$(openssl rand -hex 16)
sudo sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg\['blowfish_secret'\] = '$BLOWFISH_SECRET';/" /usr/share/phpmyadmin/config.inc.php
sudo chown -R apache:apache /usr/share/phpmyadmin
sudo chmod 777 /usr/share/phpmyadmin/tmp
sudo chown -R root:apache /var/lib/php/opcache/ /var/lib/php/session/ /var/lib/php/wsdlcache/

# Crea una nueva base de datos y usuario para phpMyAdmin
echo -e "${BLUE}Configurando la base de datos para phpMyAdmin...${NC}"
mysql -u root -p"$ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE phpmyadmin;
CREATE USER 'pma'@'localhost' IDENTIFIED BY '$PMA_PASSWORD';
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost';
CREATE DATABASE nextcloud;
CREATE USER 'nextcloud_user'@'localhost' IDENTIFIED BY '$NXT_PASSWORD';
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud_user'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo -e "${BLUE}Importando esquema de la base de datos de phpMyAdmin...${NC}"
cd /usr/share/phpmyadmin/sql
mysql -u root -p"$ROOT_PASSWORD" phpmyadmin < create_tables.sql

# Configuración de Apache
echo -e "${BLUE}Añadiendo servicios de Apache y MariaDB al firewall...${NC}"
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --zone=public --add-service=mysql --permanent
sudo firewall-cmd --reload

# Verifica si el directorio /etc/httpd/sites-available/ existe, si no, lo crea
if [ ! -d /etc/httpd/conf.d/ ]; then
    echo -e "${BLUE}Creando directorio de configuración...${NC}"
    sudo mkdir -p /etc/httpd/conf.d/
    echo -e "${GREEN}Directorio creado...${NC}"
fi

# Configuración de servidor virtual
CONFIG_FILE="/etc/httpd/conf.d/nextcloud.conf"
# Comprueba si el archivo ya existe y lo borra para evitar problemas de permisos
if [ -f "$CONFIG_FILE" ]; then
    sudo rm "$CONFIG_FILE"
fi
# Usa sudo para crear el archivo con privilegios elevados
sudo touch "$CONFIG_FILE"
sudo chmod 644 "$CONFIG_FILE"
cat <<EOF | sudo tee "$CONFIG_FILE" > /dev/null
<VirtualHost *:80>
  DocumentRoot /var/www/nextcloud/
  ServerName  nextcloud.home

  <Directory /var/www/nextcloud/>
    Require all granted
    AllowOverride All
    Options FollowSymLinks MultiViews
    <IfModule mod_dav.c>
      Dav off
    </IfModule>
  </Directory>

  Alias /phpmyadmin /usr/share/phpmyadmin

  <Directory /usr/share/phpmyadmin>
    Options FollowSymLinks
    DirectoryIndex index.php
    AllowOverride All

    <IfModule mod_authz_core.c>
      Require all granted
    </IfModule>
    <IfModule !mod_authz_core.c>
      Order Deny,Allow
      Deny from All
      Allow from All
    </IfModule>
  </Directory>

  <Directory /usr/share/phpmyadmin/setup>
    <IfModule mod_authz_core.c>
      Require all granted
    </IfModule>
    <IfModule !mod_authz_core.c>
      Order Deny,Allow
      Deny from All
      Allow from All
    </IfModule>
  </Directory>

  <Directory /usr/share/phpmyadmin/libraries>
    Deny from All
  </Directory>

  <Directory /usr/share/phpmyadmin/setup/lib>
    Deny from All
  </Directory>

  ErrorLog /var/log/httpd/error_nextcloud.log
  CustomLog /var/log/httpd/access_nextcloud.log combined

</VirtualHost>
EOF
sudo chown -R apache:apache /var/www/nextcloud
echo -e "${GREEN}Archivo de configuración creado en: $CONFIG_FILE...${NC}"

# Crear directorio home para almacenamiento de datos de Nextcloud
sudo mkdir -p /home/nextcloud/data
sudo chown -R apache:apache /home/nextcloud/

# Habilitar e iniciar Apache
echo -e "${BLUE}Habilitando Apache...${NC}"
sudo systemctl enable httpd
echo -e "${BLUE}Iniciando Apache...${NC}"
sudo systemctl start httpd

echo -e "${GREEN}Configuraciones completadas exitosamente.${NC}"
