# flus-web-template

Template repo for FLUS website

chmod +x setup_environment.sh

sudo ./setup_environment.sh

# Configuración de PostgreSQL

echo "Configurando PostgreSQL..."
sudo -iu postgres initdb --locale=C.UTF-8 --encoding=UTF8 -D /var/lib/postgres/data --data-checksums

sudo systemctl enable postgresql
sudo systemctl start postgresql

sudo -u postgres createuser --interactive
sudo -u postgres createdb my_database
sudo -u postgres psql

ALTER USER "my_user" WITH PASSWORD 'my_secure_password';
GRANT ALL PRIVILEGES ON DATABASE "my_database" TO "my_user";

sudo systemctl restart postgresql

# Configuración de Nginx

sudo systemctl enable nginx
sudo systemctl start nginx

sudo nano /etc/nginx/sites-available/tu_proyecto

server {
listen 80;
server_name localhost;

    location / {
        proxy_pass http://127.0.0.1:3000;  # Next.js frontend
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /api {
        proxy_pass http://127.0.0.1:1337;  # Strapi backend
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

}

sudo mkdir /etc/nginx/sites-enabled
sudo ln -s /etc/nginx/sites-available/flus-web /etc/nginx/sites-enabled/

sudo nginx -t
sudo systemctl reload nginx

# Strapi

cd strapi-backend
npm install

# Podman tutorial zero to herofull 1 hour course
https://www.youtube.com/watch?v=YXfA5O5Mr18

mkdir $HOME/.config/containers
touch $HOME/.config/containers/registries.conf

## Agregar esto para que se agregue al archivo registries.conf

echo -e "# Basic configuration for podman.\n\
\n\
[registries]\n\
  [registries.search]\n\
  registries = [\"docker.io\", \"quay.io\", \"ghcr.io\"]\n\
\n\
  [registries.insecure]\n\
  registries = []\n\
\n\
  [registries.block]\n\
  registries = []\n\
\n\
unqualified-search-registries = [\"docker.io\"]" >> $HOME/.config/containers/registries.conf

