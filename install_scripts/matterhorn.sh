############
# Matterhorn
############

echo "Installing Matterhorn"

SHARED_DIR=$1

if [ -f "$SHARED_DIR/install_scripts/config" ]; then
  . $SHARED_DIR/install_scripts/config
fi

if [ ! -f "$DOWNLOAD_DIR/matterhorn-1.4.x.tar.gz" ]; then
  echo -n "Downloading Matterhorn 1.4..."
  wget -q "https://github.com/uhlibraries-digital/avalon-felix/archive/1.4.x.tar.gz" -O "$DOWNLOAD_DIR/matterhorn-1.4.x.tar.gz"
  echo " done"
fi

adduser --disabled-password --gecos "" matterhorn

cp -f $DOWNLOAD_DIR/matterhorn-1.4.x.tar.gz /tmp
cd /tmp
tar xvf matterhorn-1.4.x.tar.gz
mv avalon-felix-1.4.x /usr/local/matterhorn

chown -R matterhorn:matterhorn /usr/local/matterhorn

# Install startup script
wget -q --no-check-certificate https://raw.github.com/avalonmediasystem/config-files/master/matterhorn/matterhorn_init.sh
mv matterhorn_init.sh /etc/init.d/matterhorn
chmod 755 /etc/init.d/matterhorn
update-rc.d matterhorn defaults

# Setup avalon media locations for matterhorn
adduser --disabled-password --gecos "" avalon
usermod -G avalon matterhorn

mkdir -p /var/www/avalon/public
chown -R avalon:avalon /var/www/avalon

mkdir -p /usr/local/masterfiles
chown avalon:avalon /usr/local/masterfiles

mkdir -p /usr/local/red5/webapps/avalon/streams
chown red5:avalon /usr/local/red5/webapps/avalon/streams
chmod 0775 /usr/local/red5/webapps/avalon/streams

ln -s /usr/local/red5/webapps/avalon/streams /var/avalon/rtmp_streams

mkdir /var/avalon/hls_streams
chown matterhorn:matterhorn /var/avalon/hls_streams/

ln -s /var/avalon/hls_streams/ /var/www/avalon/public/streams
chmod 0775 /var/avalon/hls_streams/

# Install Matterhorn config
cp -f $SHARED_DIR/config/config.properties /usr/local/matterhorn/etc/

# Optimize Matterhorn System Resources
touch /etc/security/limits.d/99-matterhorn.conf
echo "matterhorn      hard    nproc   4096" >> /etc/security/limits.d/99-matterhorn.conf
echo "matterhorn      soft    nproc   4096" >> /etc/security/limits.d/99-matterhorn.conf
chmod 644 /etc/security/limits.d/99-matterhorn.conf
