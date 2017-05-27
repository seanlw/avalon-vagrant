############
# Solr
############

echo "Installing Solr"

SHARED_DIR=$1

if [ -f "$SHARED_DIR/install_scripts/config" ]; then
  . $SHARED_DIR/install_scripts/config
fi

if [ ! -f "$DOWNLOAD_DIR/solr-6.4.2.tgz" ]; then
  echo -n "Downloading Solr 6.4.2..."
  wget -q "http://archive.apache.org/dist/lucene/solr/6.4.2/solr-6.4.2.tgz" -O "$DOWNLOAD_DIR/solr-6.4.2.tgz"
  echo " done"
fi

cp -f "$DOWNLOAD_DIR/solr-6.4.2.tgz" "/tmp"
cd /tmp
tar xzf solr-6.4.2.tgz solr-6.4.2/bin/install_solr_service.sh --strip-components=2
bash ./install_solr_service.sh solr-6.4.2.tgz -f

mkdir -p /tmp/avalon_solr/
wget -q https://raw.githubusercontent.com/avalonmediasystem/avalon/develop/solr/config/solrconfig.xml -O /tmp/avalon_solr/solrconfig.xml
wget -q https://raw.githubusercontent.com/avalonmediasystem/avalon/develop/solr/config/schema.xml -O /tmp/avalon_solr/schema.xml

su - solr -c "/opt/solr/bin/solr create_core -c avalon -d /tmp/avalon_solr"
