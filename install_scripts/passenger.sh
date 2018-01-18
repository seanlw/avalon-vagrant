############
# Passenger
############

echo "Installing Apache Passenger and Ruby"

SHARED_DIR=$1

if [ -f "$SHARED_DIR/install_scripts/config" ]; then
  . $SHARED_DIR/install_scripts/config
fi

su - avalon << EOF
gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
curl -sSL https://get.rvm.io | bash -s stable
source /home/avalon/.rvm/scripts/rvm

rvm install 2.4.1
rvm  --default use 2.4.1

echo "Installing passenger..."
gem install passenger -v 5.1.3 -q
passenger-install-apache2-module --auto
EOF

cp -f $SHARED_DIR/config/passenger.conf /etc/apache2/mods-available/passenger.conf

a2enmod rewrite
ln -s /etc/apache2/mods-available/passenger.conf /etc/apache2/mods-enabled/passenger.conf

# Apache security config
wget -q --no-check-certificate https://raw.github.com/avalonmediasystem/config-files/master/sbin/avalon_auth -O /usr/local/sbin/avalon_auth
chmod +x /usr/local/sbin/avalon_auth

cp -f $SHARED_DIR/config/10-mod_rewrite.conf /etc/apache2/conf-available/mod_rewrite.conf
ln -s /etc/apache2/conf-available/mod_rewrite.conf /etc/apache2/conf-enabled/mod_rewrite.conf

# Virtual Host config
rm /etc/apache2/sites-enabled/000-default.conf
cp -f $SHARED_DIR/config/20-avalon.conf /etc/apache2/sites-available/avalon.conf
a2ensite avalon
