###
# BASICS
###

SHARED_DIR=$1

if [ -f "$SHARED_DIR/install_scripts/config" ]; then
  . $SHARED_DIR/install_scripts/config
fi

# Update
apt-get -y update
apt-get -y upgrade

# Setup apt defaults
debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
debconf-set-selections <<< 'iptables-persistent iptables-persistent/autosave_v4 boolean true'
debconf-set-selections <<< 'iptables-persistent iptables-persistent/autosave_v6 boolean true'

# Install needed packages
apt-get -y install build-essential iptables-persistent libreadline6-dev zlib1g-dev libyaml-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev cmake bison byacc cscope ctags cvs diffstat doxygen flex gfortran gettext git indent intltool libtool patch patchutils rcs subversion swig systemtap libncurses5-dev pkg-config sqlite3 git-core libgmp3-dev libreadline-dev libgdbm-dev libmysqlclient-dev nodejs libcurl4-openssl-dev apache2-dev libapr1-dev libaprutil1-dev ffmpeg mediainfo openjdk-8-jdk default-jre default-jdk tomcat7 lsof mysql-server apache2 libsqlite3-dev gnupg2 redis-server

if [ ! -f /usr/sbin/lsof ]; then
  ln -s /usr/bin/lsof /usr/sbin/lsof
fi

# Install iptable rules
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 1935 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 8983 -j ACCEPT
iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 8984 -j ACCEPT

iptables-save > /etc/iptables/rules.v4

# Create Avalon database
mysql -uroot -proot -e "create database if not exists rails character set utf8 collate utf8_general_ci;create user if not exists 'rails'@'localhost' identified by 'rails';grant all privileges on rails.* to 'rails'@'localhost';flush privileges;"
