############
# Avalon
############

echo "Installing Avalon"

SHARED_DIR=$1

if [ -f "$SHARED_DIR/install_scripts/config" ]; then
  . $SHARED_DIR/install_scripts/config
fi

su - avalon << EOF

cd $AVALON_HOME
git clone https://github.com/avalonmediasystem/avalon
cd $AVALON_HOME/avalon
git checkout master

mv public/* /var/www/avalon/public/
rmdir public
mv  * /var/www/avalon/

printf "if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')\n\
 begin\n\
   gems_path = ENV['MY_RUBY_HOME'].split(/@/)[0].sub(/rubies/,'gems')\n\
   ENV['GEM_PATH'] = \"#{gems_path}:#{gems_path}@global\"\n\
   require 'rvm'\n\
   RVM.use_from_path! File.dirname(File.dirname(__FILE__))\n\
 rescue LoadError\n\
   raise \"RVM gem is currently unavailable.\"\n\
 end\n\
end\n\
# If you're not using Bundler at all, remove lines bellow\n\
ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', File.dirname(__FILE__))\n\
require 'bundler/setup'" > /var/www/avalon/config/setup_load_paths.rb

echo "Installing Avalon configs..."
cp -f /var/www/avalon/config/authentication.yml.example /var/www/avalon/config/authentication.yml
cp -f /var/www/avalon/config/controlled_vocabulary.yml.example /var/www/avalon/config/controlled_vocabulary.yml
cp -f $SHARED_DIR/config/database.yml /var/www/avalon/config/database.yml
cp -f $SHARED_DIR/config/solr.yml /var/www/avalon/config/solr.yml
cp -f $SHARED_DIR/config/blacklight.yml /var/www/avalon/config/blacklight.yml
cp -f $SHARED_DIR/config/fedora.yml /var/www/avalon/config/fedora.yml
cp -f $SHARED_DIR/config/matterhorn.yml /var/www/avalon/config/matterhorn.yml
cp -f $SHARED_DIR/config/browse_everything_providers.yml /var/www/avalon/config/browse_everything_providers.yml
cp -f $SHARED_DIR/config/avalon.yml /var/www/avalon/config/settings/development.yml
cp -f $SHARED_DIR/config/secrets.yml /var/www/avalon/config/secrets.yml
cp -f $SHARED_DIR/config/Gemfile /var/www/avalon/Gemfile

cd /var/www/avalon

echo "Installing more gems..."
gem install rake -q
gem install activerecord-mysql2-adapter -q
gem install mysql2 -q
gem update debugger-ruby_core_source -q
gem install bundler -q
bundle install

# Build database
rake RAILS_ENV=development db:migrate

EOF

service apache2 restart

# Install Resque
echo "Installing Resque..."
cp -f $SHARED_DIR/config/resque_init_script.sh /etc/init.d/resque
chmod 755 /etc/init.d/resque
update-rc.d resque defaults
update-rc.d resque enable
/etc/init.d/resque start

# Cleanup
echo "Cleaning up..."
rm -Rf $AVALON_HOME/avalon
echo "Done"
