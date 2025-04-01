# nginx
mkdir -p /data/nginx/conf
mkdir -p /data/nginx/log
mkdir -p /data/nginx/html

docker run --name nginx -d nginx:stable-perl

docker cp nginx:/etc/nginx/nginx.conf /data/nginx/conf/nginx.conf
docker cp nginx:/etc/nginx/conf.d /data/nginx/conf/conf.d
docker cp nginx:/usr/share/nginx/html /data/nginx/html

docker rm -f nginx

docker run \
-p 80:80 \
--name nginx \
-v /data/nginx/conf/nginx.conf:/etc/nginx/nginx.conf \
-v /data/nginx/conf/conf.d:/etc/nginx/conf.d \
-v /data/nginx/log:/var/log/nginx \
-v /data/nginx/html:/usr/share/nginx/html \
-d nginx:stable-perl

# postgres
docker run -d \
  --name postgres \
  -e POSTGRES_USER=admin \
  -e POSTGRES_PASSWORD=test123 \
  -e POSTGRES_DB=work_logging \
  -p 15432:5432 \
  -v /data/postgresql:/var/lib/postgresql/data \
  postgres:latest



