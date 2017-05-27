############
# Red5
############

echo "Installing Red5 Media Server"

SHARED_DIR=$1

if [ -f "$SHARED_DIR/install_scripts/config" ]; then
  . $SHARED_DIR/install_scripts/config
fi

if [ ! -f "$DOWNLOAD_DIR/red5-1.0.1.tar.gz" ]; then
  echo -n "Downloading Red5 1.0.1..."
  wget -q "http://repo.avalonmediasystem.org/red5-1.0.1.tar.gz" -O "$DOWNLOAD_DIR/red5-1.0.1.tar.gz"
  echo " done"
fi

adduser --disabled-password --gecos "" red5

cp -f $DOWNLOAD_DIR/red5-1.0.1.tar.gz /tmp/red5-1.0.1.tar.gz
cd /tmp
tar xvf red5-1.0.1.tar.gz
mv red5-server-1.0 /usr/local/red5
chown -R red5:red5 /usr/local/red5

# Install startup script
cp -f $SHARED_DIR/config/red5_init_script.sh /etc/init.d/red5
chmod 755 /etc/init.d/red5
update-rc.d red5 defaults
update-rc.d red5 enable

/etc/init.d/red5 start
