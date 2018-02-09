###
# Nginx
###

SHARED_DIR=$1

if [ -f "$SHARED_DIR/install_scripts/config" ]; then
  . $SHARED_DIR/install_scripts/config
fi

wget -O - http://installrepo.kaltura.org/repo/apt/xenial/kaltura-deb-256.gpg.key|apt-key add -
echo "deb [arch=amd64] http://installrepo.kaltura.org/repo/apt/xenial mercury main" > /etc/apt/sources.list.d/kaltura.list

apt-get update

debconf-set-selections <<< 'kaltura-nginx kaltura-nginx/is_kaltura_server boolean false'
debconf-set-selections <<< 'kaltura-nginx kaltura-nginx/rtmp_port string 1935'
debconf-set-selections <<< 'kaltura-nginx kaltura-nginx/path_to_media_files string /var/avalon/rtmp_streams'
debconf-set-selections <<< 'kaltura-nginx kaltura-nginx/nginx_port string 8181'
debconf-set-selections <<< 'kaltura-nginx kaltura-nginx/nginx_hostname string avalon'
debconf-set-selections <<< 'kaltura-nginx kaltura-nginx/vod_mod select Local'
debconf-set-selections <<< 'kaltura-nginx kaltura-nginx/is_ssl boolean false'

apt-get install -y kaltura-nginx

rm -f /opt/kaltura/nginx/conf/nginx.conf
cp $SHARED_DIR/config/nginx.default.conf /opt/kaltura/nginx/conf/nginx.conf

service kaltura-nginx restart
