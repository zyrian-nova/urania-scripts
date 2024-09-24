#!/bin/bash
# Descripción

# Define el color azul
NC='\033[0m' # No color
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'

# Actualiza el sistema
echo -e "${BLUE}Actualizando el sistema...${NC}"
sudo dnf update -y
echo -e "${GREEN}Actualización terminada...${NC}"

# Instala herramientas
echo -e "${BLUE}Instalando herramientas...${NC}"
sudo dnf install nginx mariadb-server openssl net-tools bind-utils traceroute vim rsyslog yum-utils dnf-utils util-linux-user wget unzip curl -y
echo -e "${GREEN}Instalación de herramientas terminada...${NC}"

# Instalación de PHP 8.3 desde el repositorio Remi
echo -e "${BLUE}Instalando PHP 8.3...${NC}"
sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
sudo dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
sudo dnf module reset php -y
sudo dnf module install php:remi-8.3 -y
sudo dnf install php php-cli php-gd php-curl php-zip php-mbstring nodejs php php-pdo php-pecl-zip php-json php-mbstring php-mysqlnd php-bcmath php-pecl-mcrypt php-process php-intl php-ldap php-smbclient php-gmp php-pecl-imagick php-pecl-memcached -y
echo -e "${GREEN}Instalación de PHP terminada...${NC}"

# Verifica si el directorio Descargas existe, si no, lo crea
echo -e "${BLUE}Descargando herramientas externas...${NC}"
echo -e "${BLUE}Verificando el directorio de Descargas...${NC}"
if [ ! -d "$HOME/Descargas" ]; then
    mkdir -p "$HOME/Descargas"
    echo -e "${GREEN}Directorio creado...${NC}"
fi
echo -e "${GREEN}Directorio listo...${NC}"

# Cambia al directorio Descargas
cd "$HOME/Descargas"

# Instalación de Composer
echo -e "${BLUE}Instalando Composer...${NC}"
wget https://getcomposer.org/installer -O composer-installer.php
sudo php composer-installer.php --filename=composer --install-dir=/usr/local/bin

# Crear un enlace simbólico para Composer
echo -e "${GREEN}Creando enlace simbólico para Composer...${NC}"
sudo ln -s /usr/local/bin/composer /usr/bin/composer

# Instalación de phpMyAdmin
echo -e "${BLUE}Instalando phpMyAdmin...${NC}"
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
unzip phpMyAdmin-5.2.1-all-languages.zip
sudo mv phpMyAdmin-5.2.1-all-languages /usr/share/phpMyAdmin
sudo mkdir /usr/share/phpMyAdmin/tmp
sudo cp /usr/share/phpMyAdmin/config.sample.inc.php /usr/share/phpMyAdmin/config.inc.php
# Vuelve al directorio anterior
cd "$HOME"
echo -e "${GREEN}Instalación terminada...${NC}"

# Configuración de Nginx
echo -e "${BLUE}Añadiendo servicios de Nginx y MariaDB al firewall...${NC}"
sudo firewall-cmd --zone=public --add-service=http --permanent
sudo firewall-cmd --zone=public --add-service=https --permanent
sudo firewall-cmd --zone=public --add-service=mysql --permanent
sudo firewall-cmd --reload

# Desactiva SELinux
echo -e "${BLUE}Desactivando SELinux...${NC}"
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=disabled/' /etc/selinux/config
echo -e "${GREEN}SELinux desactivado...${NC}"

# Configuración de MariaDB
echo -e "${BLUE}Habilitando MariaDB...${NC}"
sudo systemctl enable mariadb
echo -e "${BLUE}Iniciando MariaDB...${NC}"
sudo systemctl start mariadb

# Ejecuta mysql_secure_installation
echo -e "${BLUE}Ejecutando mysql_secure_installation...${NC}"
sudo mysql_secure_installation

# Solicita al usuario que introduzca la contraseña del root de MariaDB
echo -e "${BLUE}Introduce la contraseña de root de MariaDB:${NC}"
read -s ROOT_PASSWORD
echo -e "${GREEN}¡Éxito!${NC}"

# Solicita al usuario que introduzca la contraseña del root de MariaDB
echo -e "${BLUE}Introduce la contraseña de que tendrá el usuario 'pma':${NC}"
read -s PMA_PASSWORD
echo -e "${GREEN}¡Éxito!${NC}"

# Genera un secreto para el archivo de configuración
echo -e "${YELLOW}Generando blowfish secret...${NC}"
BLOWFISH_SECRET=$(openssl rand -hex 16)
sudo sed -i "s/\$cfg\['blowfish_secret'\] = '';/\$cfg\['blowfish_secret'\] = '$BLOWFISH_SECRET';/" /usr/share/phpMyAdmin/config.inc.php
sudo chown -R nginx:nginx /usr/share/phpMyAdmin
sudo chmod 777 /usr/share/phpMyAdmin/tmp
sudo chown -R root:nginx /var/lib/php/opcache/ /var/lib/php/session/ /var/lib/php/wsdlcache/

# Crea una nueva base de datos y usuario para phpMyAdmin
echo -e "${BLUE}Configurando la base de datos para phpMyAdmin...${NC}"
mysql -u root -p"$ROOT_PASSWORD" <<MYSQL_SCRIPT
CREATE DATABASE phpmyadmin;
CREATE USER 'pma'@'localhost' IDENTIFIED BY '$PMA_PASSWORD';
GRANT ALL PRIVILEGES ON phpmyadmin.* TO 'pma'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo -e "${BLUE}Importando esquema de la base de datos de phpMyAdmin...${NC}"
cd /usr/share/phpMyAdmin/sql
mysql -u root -p"$ROOT_PASSWORD" phpmyadmin < create_tables.sql

# Configuración de servidor virtual de phpMyAdmin
echo -e "${BLUE}Introduce el nombre del servidor para PHPMyAdmin (ejemplo: ${RED}hola${BLUE}.tu-dominio.com/phpMyAdmin):...${NC}"
read SERVER_NAME
CONFIG_FILE="/etc/nginx/conf.d/phpmyadmin.conf"
# Comprueba si el archivo ya existe y lo borra para evitar problemas de permisos
if [ -f "$CONFIG_FILE" ]; then
    sudo rm "$CONFIG_FILE"
fi
# Usa sudo para crear el archivo con privilegios elevados
sudo touch "$CONFIG_FILE"
sudo chmod 644 "$CONFIG_FILE"
cat <<EOF | sudo tee "$CONFIG_FILE" > /dev/null
server {
    listen 80;
    server_name  ${SERVER_NAME}.example.dev;
    return       301 https://${SERVER_NAME}.example.dev$request_uri;
    access_log   off; error_log    off;
}

server {
    listen	 443 ssl http2;
    server_name  ${SERVER_NAME}.example.dev;
    #include      ssl_wildcard_fullchain.inc;

    access_log   /var/log/nginx/${SERVER_NAME}.access.log main;
    error_log    /var/log/nginx/${SERVER_NAME}.error.log;

    root /var/www/${SERVER_NAME};
    index index.html index.htm index.php;

    location / {
	try_files \$uri \$uri/ /index.php?\$query_string;
        }
        location ~ \.php$ {
            	try_files \$uri =404;
		fastcgi_pass unix:/var/run/php-fpm/www.sock;
            	fastcgi_index index.php;
		fastcgi_param PATH_INFO \$fastcgi_path_info;
            	fastcgi_param PATH_TRANSLATED \$document_root\$fastcgi_path_info;
            	fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            	include fastcgi_params;
        }

        location /phpMyAdmin {
           root /usr/share/;
           index index.php index.html index.htm;
           location ~ ^/phpMyAdmin/(.+\.php)$ {
                           try_files \$uri =404;
                           root /usr/share/;
                           fastcgi_pass unix:/var/run/php-fpm/www.sock; # or 127.0.0.1:9000
                           fastcgi_index index.php;
                           fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                           include /etc/nginx/fastcgi_params;
            }
        }
}
EOF
echo -e "${GREEN}Archivo de configuración de Sitio y PHPMyAdmin creado en: $CONFIG_FILE...${NC}"

# Habilitar e iniciar Nginx
echo -e "${BLUE}Configurando Nginx...${NC}"
sudo cp /etc/php-fpm.d/www.conf /etc/php-fpm.d/www.conf.bak
sudo sed -i 's/^user = apache$/user = nginx/' /etc/php-fpm.d/www.conf
sudo sed -i 's/^group = apache$/group = nginx/' /etc/php-fpm.d/www.conf
echo -e "${BLUE}Habilitando Nginx...${NC}"
sudo systemctl enable nginx
echo -e "${BLUE}Iniciando Nginx...${NC}"
sudo systemctl start nginx

echo -e "${GREEN}Configuraciones completadas exitosamente.${NC}"
