These instructions are for Avalon 6 on Ubuntu 16.04 and were adapted from the CentOS 6 instructions found [here](https://wiki.dlib.indiana.edu/display/VarVideo/Manual+Installation+Instructions#ManualInstallationInstructions-FedoraCommonsRepository). They assume that you have the base system set up including DNS and hostname configurations. All steps are performed as root, or using sudo, except when otherwise stated.

## Ready the Installation Environment

Install all dependencies including applications and development libraries for future steps:

    apt-get install build-essential libreadline6-dev zlib1g-dev libyaml-dev libffi-dev libssl-dev libxml2-dev libxslt1-dev cmake bison byacc cscope ctags cvs diffstat doxygen flex gfortran gettext git indent intltool libtool patch patchutils rcs subversion swig systemtap libncurses5-dev pkg-config sqlite3 git-core libgmp3-dev libreadline-dev libgdbm-dev libmysqlclient-dev nodejs libcurl4-openssl-dev apache2-dev libapr1-dev libaprutil1-dev ffmpeg mediainfo openjdk-8-jdk default-jre default-jdk tomcat7 lsof mysql-server apache2 libsqlite3-dev gnupg2 redis-server

Set MySQL root password when prompted.

Due to a hard coded path in Avalon, and the placement of lsof in Ubuntu, we need to make the following symbolic link:

    ln -s /usr/bin/lsof /usr/sbin/lsof

Configure iptables

There are a couple ways to configure iptables. I like to edit the configuration file directly and restart the service:

    nano /etc/iptables/rules.v4

Add the following:

    -A INPUT -m state --state NEW -m tcp -p tcp --dport 22 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 443 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 1935 -j ACCEPT
    #-A INPUT -m state --state NEW -m tcp -p tcp --dport 5080 -j ACCEPT
    -A INPUT -m state --state NEW -m tcp -p tcp --dport 8080 -j ACCEPT
    #-A INPUT -m state --state NEW -m tcp -p tcp --dport 8983 -j ACCEPT
    #-A INPUT -m state --state NEW -m tcp -p tcp --dport 8984 -j ACCEPT

Note the lines that are commented out. While testing you may want to uncomment these.

Restart iptables:

    /etc/init.d/netfilter-persistent restart

## Main Components

### Fedora Commons Repository

Configure Apache Tomcat

Change port from 8080 to 8984 on line 73:

    nano /etc/tomcat7/server.xml

Add Tomcat manager user

By default, no user has access to the Tomcat Manager App. Define a user with access to the manager-gui role. Below is a very basic example:

    nano /etc/tomcat7/tomcat-users.xml

Add something like this:

    <tomcat-users>
      <role rolename="manager-gui"/>
      <user username="admin" password="<insert strong password here>" roles="manager-gui"/>
    </tomcat-users>

Configure Tomcat for Fedora:

    nano /etc/default/tomcat7

Add the following:

    JAVA_OPTS="${JAVA_OPTS} -Dfcrepo.modeshape.configuration=classpath:/config/file-simple/repository.json -Dfcrepo.home=/var/avalon/fedora/"

Restart Tomcat:

    /etc/init.d/tomcat7 restart

Download and run the fcrepo installer:

    mkdir -p /var/avalon/fedora

    chown tomcat7:tomcat7 /var/avalon/fedora

    wget https://github.com/fcrepo4/fcrepo4/releases/download/fcrepo-4.7.1/fcrepo-webapp-4.7.1.war -O /var/lib/tomcat7/webapps/fedora4.war

See if you can access Fedora's REST interface at http://<server host name>:8984/fedora4/rest

### Solr

Avalon makes use of Solr through the Blacklight gem for faceting and relevance-based searching.

Download the solr tarball and run the installation script:

    wget http://archive.apache.org/dist/lucene/solr/6.4.2/solr-6.4.2.tgz

    tar xzf solr-6.4.2.tgz solr-6.4.2/bin/install_solr_service.sh --strip-components=2

    bash ./install_solr_service.sh solr-6.4.2.tgz

By default, the script extracts the distribution archive into /opt, configures Solr to write files into /var/solr, and runs Solr as the solr user. Change the defaults if you choose.

Create Avalon core for Solr:

    mkdir -p /tmp/avalon_solr/

    wget https://raw.githubusercontent.com/avalonmediasystem/avalon/develop/solr/config/solrconfig.xml -O /tmp/avalon_solr/solrconfig.xml

    wget https://raw.githubusercontent.com/avalonmediasystem/avalon/develop/solr/config/schema.xml -O /tmp/avalon_solr/schema.xml

Run the next command as the solr user:

    su solr

    /opt/solr/bin/solr create_core -c avalon -d /tmp/avalon_solr

    exit

If you have successfully installed Solr you should be able to access the dashboard page at http://<server host name>:8983/solr

### MySQL

Avalon uses MySQL for storing search queries, user data and roles, and as a back end for asynchronously sending requests to Matterhorn.

Create databases and users

Enter the mysql monitor using the root credentials:

    mysql -uroot -p

Create a database for the Avalon web application and add a user to it:

    create database rails character set utf8 collate utf8_general_ci;

    create user 'rails'@'localhost' identified by 'set_rails_user_pass_here';

    grant all privileges on rails.* to 'rails'@'localhost';

    flush privileges;

### Red5 Media Server

Red5 is an open source alternative to Adobe Media Server. If using the Adobe Media Server you can skip to the next step.

Create a red5 user:

    adduser --disabled-password --gecos "" red5

Download and install Red5:

    wget http://repo.avalonmediasystem.org/red5-1.0.1.tar.gz

    tar xvf red5-1.0.1.tar.gz

    mv red5-server-1.0 /usr/local/red5

    chown -R red5:red5 /usr/local/red5

Download the init script and add LSB headers and other lines:

    wget https://raw.github.com/avalonmediasystem/avalon-installer/master/modules/red5/templates/red5_init_script.erb -O red5_init_script.sh

    nano red5_init_script.sh

Replace:

    # Startup script for Red5 flash streaming server on RedHat/CentOS (cPanel)
    # chkconfig: 2345 95 55
    # description: Red5 Flash Streaming Server
    # processname: red5

With:

    ### BEGIN INIT INFO
    # Provides:          red5
    # Required-Start:    $remote_fs
    # Required-Stop:     $remote_fs
    # Default-Start:     2 3 4 5
    # Default-Stop:      0 1 6
    # Short-Description: Start daemon at boot time
    # Description:       Red5 Flash Streaming Server
    ### END INIT INFO

Replace:

    . /etc/rc.d/init.d/functions

With:

    . /lib/lsb/init-functions

Replace:

    success $"$PROG startup"

With:

    log_success_msg

Replace:

    failure $"$PROG startup"

With:

    log_failure_msg

Move to init.d directory and update the runlevels:

    mv red5_init_script.sh /etc/init.d/red5

    chmod 755 /etc/init.d/red5

    update-rc.d red5 defaults

    update-rc.d red5 enable

Restart Red5:

    /etc/init.d/red5 start

### Matterhorn

Create matterhorn user:

    adduser --disabled-password --gecos "" matterhorn

Install matterhorn:

    wget https://github.com/uhlibraries-digital/avalon-felix/archive/1.4.x.tar.gz

    tar xvf 1.4.x.tar.gz

    mv avalon-felix-1.4.x /usr/local/matterhorn

    chown -R matterhorn:matterhorn /usr/local/matterhorn

Download init script, move to init.d directory, and update the runlevels:

    wget --no-check-certificate https://raw.github.com/avalonmediasystem/config-files/master/matterhorn/matterhorn_init.sh

    mv matterhorn_init.sh /etc/init.d/matterhorn

    chmod 755 /etc/init.d/matterhorn

    update-rc.d matterhorn defaults

    update-rc.d matterhorn enable

Add avalon user:

    adduser --disabled-password --gecos "" avalon

Create avalon directory:

    mkdir -p /var/www/avalon/public

    chown -R avalon:avalon /var/www/avalon

Create and configure the media_path (upload) and streaming directories:

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


Configure Matterhorn:

    wget --no-check-certificate https://raw.github.com/avalonmediasystem/config-files/master/matterhorn/config.properties

    nano config.properties

Verify the configuration of the streaming directories:

    org.opencastproject.streaming.directory=/var/avalon/rtmp_streams
    org.opencastproject.hls.directory=/var/avalon/hls_streams

Replace instances of port:

    18080

With:

    8080

Finally,change admin and digest usernames and passwords:

    org.opencastproject.security.digest.user=matterhorn_digest
    org.opencastproject.security.digest.pass=set_digest_password_here

    org.opencastproject.security.admin.user=admin
    org.opencastproject.security.admin.pass=set_admin_password_here

Move the config to the appropriate spot:

    mv config.properties /usr/local/matterhorn/etc/

Also check:

    nano /usr/local/matterhorn/etc/load/org.opencastproject.organization-mh_default_org.cfg

And verify the following:

    prop.avalon.stream_base=file:///var/avalon/rtmp_streams

Adjust the encoding properties:

    nano /usr/local/matterhorn/etc/encoding/avalon.properties

Confirm the following options to all video encoding/transcoding configs when using AAC:

    -c:a aac -ab 128k -ar 44100 -ac 2 -strict -2

These settings use the native ffmpeg aac library and versions of ffmpeg pre 5 December 2015 considered this codec experimental requiring the “-strict 02” to permit use. “-ac 2” is needed to insure conversion of multi channel audio to 2 channel allowing HLS streaming to work on iOS devices.

Add matterhorn user to the avalon group:

    usermod -G avalon matterhorn

Optimize Matterhorn System Resources as seen [here](https://wiki.dlib.indiana.edu/display/VarVideo/Optimizing+Matterhorn+System+Resources):

    touch /etc/security/limits.d/99-matterhorn.conf

    echo "matterhorn      hard    nproc   4096" >> /etc/security/limits.d/99-matterhorn.conf

    echo "matterhorn      soft    nproc   4096" >> /etc/security/limits.d/99-matterhorn.conf

    chmod 644 /etc/security/limits.d/99-matterhorn.conf

### Apache Passenger and Ruby

All steps until next "exit" command will be performed as the avalon user:

    su - avalon

Install RVM and ruby 2.2.5:

    gpg2 --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

    curl -L https://get.rvm.io | bash -s stable --ruby=2.2.5

Source the RVM shell:

    source /home/avalon/.rvm/scripts/rvm

    rvm use 2.2.5

Install Passenger via Gem:

    gem install passenger

Check to make sure passenger installed in the expected location:

    passenger-config --root

Output should be (version will vary):

    /home/avalon/.rvm/gems/ruby-2.2.5/gems/passenger-5.1.3

Build passenger for your version of Apache and Ruby:

    passenger-install-apache2-module

Copy the suggested Apache configuration file settings for later.

Exit avalon user to root user to configure apache:

    exit

Create an apache configuration file:

    nano /etc/apache2/mods-available/passenger.conf

Versions may need to be changed based off of the current version of ruby and passenger:

    LoadModule passenger_module /home/avalon/.rvm/gems/ruby-2.2.5/gems/passenger-5.1.3/buildout/apache2/mod_passenger.so
    <IfModule passenger_module>
      PassengerRoot /home/avalon/.rvm/gems/ruby-2.2.5/gems/passenger-5.1.3
      PassengerDefaultRuby /home/avalon/.rvm/gems/ruby-2.2.5/wrappers/ruby
      PassengerMaxPoolSize 30
      PassengerPoolIdleTime 300
      PassengerMaxInstancesPerApp 0
      PassengerMinInstances 3
      PassengerSpawnMethod smart-lv2
    </IfModule>

Link/load module configuration:

    ln -s /etc/apache2/mods-available/passenger.conf /etc/apache2/mods-enabled/passenger.conf

Ensure that the rewrite module is linked/loaded:

    ln -s /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load

Apache security configuration:

    wget --no-check-certificate https://raw.github.com/avalonmediasystem/config-files/master/sbin/avalon_auth -O /usr/local/sbin/avalon_auth

    chmod +x /usr/local/sbin/avalon_auth

    wget --no-check-certificate https://raw.github.com/avalonmediasystem/config-files/master/apache/10-mod_rewrite.conf -O /etc/apache2/conf-available/mod_rewrite.conf

    nano /etc/apache2/conf-available/mod_rewrite.conf

Replace:

    RewriteLock /tmp/avalon_rewrite_lock

With:

    Mutex sem

Link/load security configuration:

    ln -s /etc/apache2/conf-available/mod_rewrite.conf /etc/apache2/conf-enabled/mod_rewrite.conf

Virtual host configuration:

    rm /etc/apache2/sites-enabled/000-default.conf

    wget --no-check-certificate https://raw.github.com/avalonmediasystem/config-files/master/apache/20-avalon.conf -O /etc/apache2/sites-available/avalon.conf

    ln -s /etc/apache2/sites-available/avalon.conf /etc/apache2/sites-enabled/avalon.conf

    nano /etc/apache2/sites-enabled/avalon.conf

Remove:

    NameVirtualHost *:80

Replace instances of:

    /var/log/httpd/

With:

    /var/log/apache2/

Add this line inside the VirtualHost tag:

    RailsEnv development

If using SSL, the following fix should be added to address BEAST, POODLE, RC4 issues (after the SSLEngine on):

    SSLProtocol all -SSLv2 -SSLv3
    SSLCipherSuite ALL:!ADH:!EXPORT:!SSLv2:!RC4:+HIGH:+MEDIUM:-LOW

Restart apache:

    /etc/init.d/apache2 restart

All steps until next "exit" command will be performed as the avalon user:

    su - avalon

With apache running, check passenger-status:

    which passenger-status

Output should be:

    /home/avalon/.rvm/gems/ruby-2.2.5/bin/passenger-status

### Avalon

Grab Avalon code from github:

    cd ~

    git clone https://github.com/avalonmediasystem/avalon.git

Make sure you are in the master branch (should be by default):

    cd avalon

    git checkout master

Move files:

    cd avalon

    mv public/* /var/www/avalon/public/

    rmdir public

    mv  * /var/www/avalon/

Configure Avalon

Create setup_load_paths.rb:

    nano /var/www/avalon/config/setup_load_paths.rb

Add:

    if ENV['MY_RUBY_HOME'] && ENV['MY_RUBY_HOME'].include?('rvm')
       begin
         gems_path = ENV['MY_RUBY_HOME'].split(/@/)[0].sub(/rubies/,'gems')
         ENV['GEM_PATH'] = "#{gems_path}:#{gems_path}@global"
         require 'rvm'
         RVM.use_from_path! File.dirname(File.dirname(__FILE__))
       rescue LoadError
         raise "RVM gem is currently unavailable."
       end
     end
     # If you're not using Bundler at all, remove lines bellow
     ENV['BUNDLE_GEMFILE'] = File.expand_path('../Gemfile', File.dirname(__FILE__))
     require 'bundler/setup'

Copy over authentication yaml:

    cd /var/www/avalon/config

    cp authentication.yml.example authentication.yml

Configure database settings:

    nano database.yml

Replace database.yml with the correct values for your environment:

    development:
      adapter: mysql2
      host: localhost
      database: rails
      username: rails
      password: replace_with_password_set_in_mysql_step
      pool: 5
      timeout: 5000

Configure mysql adapter:

    gem install activerecord-mysql2-adapter

    gem install mysql2

    nano /var/www/avalon/Gemfile

Comment out:

    gem 'sqlite3'

And:

    group :mysql, optional: true do
      gem 'mysql2'
    end

Add this line:

    gem 'mysql2', '~>0.3.20'

Run the bundle install:

    cd /var/www/avalon

    gem update debugger-ruby_core_source

    gem install bundler

    bundle install

Finish configuring Avalon:

Edit solr.yml:

    nano /var/www/avalon/config/solr.yml

Change to following:

    development:
      url: http://localhost:8983/solr/avalon

Edit blacklight.yml:

    nano /var/www/avalon/config/blacklight.yml

Change to following:

    development:
      adapter: solr
      url: http://localhost:8983/solr/avalon

Edit fedora.yml:

    nano /var/www/avalon/config/fedora.yml

Change the following:

    development:
      user: fedoraAdmin
      password: fedoraPassword
      url: http://127.0.0.1:8984/fedora4/rest
      base_path: /dev

Create matterhorn.yml:

    nano /var/www/avalon/config/matterhorn.yml

Add:

    development:
      url: http://matterhorn_digest:replace_with_password_set_in_matterhorn_step@localhost:8080/

Create avalon.yml and change DNS as appropriate:

    nano /var/www/avalon/config/avalon.yml

Add the following and change DNS and other settings where appropriate:

    development:

      domain:
        host: change.me.edu
        port: 80

      dropbox:
        path: '/var/avalon/dropbox/'
        upload_uri: 'V:\TBD\'
    #    username: 'test'
    #    password: 'test'
    #    notification_email_address: ''

      ffmpeg:
        path: '/usr/bin/ffmpeg'

      groups:
        system_groups: [administrator, group_manager, manager]

      master_file_management:
       strategy: 'delete'

      mediainfo:
       path: '/usr/bin/mediainfo'

      streaming:
       server: :generic # or :adobe
       content_path: /var/avalon/rtmp_streams
       rtmp_base: rtmp://change.me.edu/avalon
       http_base: http://change.me.edu/streams
       stream_token_ttl: 20 #minutes

      email:
       comments: 'changeme@change.me.edu'
       notification: 'changeme@change.me.edu'
       support: 'changeme@change.me.edu'
       mailer:
         smtp:
           address: 'change.me.edu'
           port: 25
           enable_starttls_auto: false

Update secrets.yml file:

    cd /var/www/avalon/config

    rake secret

Grab the output of rake secret and create secrets.yml:

    nano secrets.yml

Add the following:

    development:
      secret_key_base: PAST_SECRET_HERE

    test:
      secret_key_base: TEST_SECRET_KEY

    # Do not keep production secrets in the repository,
    # instead read values from the environment.
    production:
      secret_key_base: <%= ENV["SECRET_KEY_BASE"] %>

Create controlled_vocabulary.yml:

    cp controlled_vocabulary.yml.example controlled_vocabulary.yml

Create the database using rake:

    cd /var/www/avalon

    rake RAILS_ENV=development db:create

Run the database migrations:

    rake RAILS_ENV=development db:migrate

Set rails environment to development, if it has not defaulted to this:

    nano /var/www/avalon/config/environment.rb

On the first line make sure it says 'development':

    ENV['RAILS_ENV'] ||= 'development'

Edit Role Map:

    nano /var/www/avalon/config/role_map.yml

Change email addresses as appropriate:

    development:
      administrator:
        - changeme@change.me.edu
      manager:
        - changeme@change.me.edu
      group_manager:
        - changeme@change.me.edu

Visit your new Avalon site!
Click on "Sign in" in the upper right corner of the website main page. Set up a default identity with the following properties.

### Resque

Avalon uses Resque for background processing, which relies on Redis as its key-value store.

Start Resque - not needed if implementing init script below:

    cd /var/www/avalon/

    RAILS_ENV=development BACKGROUND=yes bundle exec rake resque:scheduler

    RAILS_ENV=development BACKGROUND=yes QUEUE=* bundle exec rake resque:work

Resque logs to log/resque.log in the avalon directory.
To restart resque, simply kill its two processes (`ps aux | grep resque`) and run the above commands again.

Exit avalon user to root user:

    exit

Create Resque Init Script:

    nano /etc/init.d/resque

Add following:

    #!/bin/bash
    ### BEGIN INIT INFO
    # Provides:          resque
    # Required-Start:    $remote_fs
    # Required-Stop:     $remote_fs
    # Default-Start:     2 3 4 5
    # Default-Stop:      0 1 6
    # Short-Description: Start daemon at boot time
    # Description:       Resque Scheduler and Worker
    ### END INIT INFO

    RAILS_ROOT="/var/www/avalon"
    ENV="development"

    case "$1" in
      start)
      echo -n "Starting Resque Scheduler and Worker: "
      su - avalon -c "cd $RAILS_ROOT && RAILS_ENV=$ENV BACKGROUND=yes bundle exec rake resque:scheduler &" >> $RAILS_ROOT/log/resque_scheduler.log 2>&1
      su - avalon -c "cd $RAILS_ROOT && RAILS_ENV=$ENV BACKGROUND=yes QUEUE=* bundle exec rake resque:work &" >> $RAILS_ROOT/log/resque_worker.log 2>&1
      echo "done."
      ;;
      stop)
      echo -n "Stopping Resque Scheduler and Worker: "
      ps -ef | grep "resque-scheduler" | head -n1 | awk '{ print $2 }' | xargs kill >> $RAILS_ROOT/log/resque_scheduler.log 2>&1
      ps -ef | grep "resque-1" | head -n1 | awk '{ print $2 }' | xargs kill >> $RAILS_ROOT/log/resque_worker.log 2>&1
      echo "done."
      ;;
      *)
      echo "Usage: $N {start|stop}" >&2
      exit 1
      ;;
    esac

    exit 0

Change permissions, set runlevels, and start resque:

    chmod 755 /etc/init.d/resque
    update-rc.d resque defaults
    update-rc.d resque enable
    /etc/init.d/resque start

### Red5 Avalon Security Webapp

    cd /usr/local/red5/webapps

    wget https://github.com/avalonmediasystem/avalon-installer/raw/master/modules/avalon/files/red5/red5-avalon.tar.gz

    tar xvzf red5-avalon.tar.gz

    chown -R red5:red5 avalon/

Edit avalon red5 properties:

    nano /usr/local/red5/webapps/avalon/WEB-INF/red5-web.properties

Add:

    avalon.serverUrl=http://localhost/

Restart Red5:

    /etc/init.d/red5 restart

If Red5 is installed and running you should be able to access http://avalon.dev:5080/

Reapply permissions to streams:

    chown red5:avalon /usr/local/red5/webapps/avalon/streams

    chmod 0775 /usr/local/red5/webapps/avalon/streams

## Additional Configurations

### Dropbox (use sftp config as below or adapt to other situations such as a SMB share)

    groupadd -r dropbox

    useradd -r avalondrop

    passwd avalondrop

    usermod -G dropbox avalondrop

    usermod -G dropbox avalon

    mkdir -p /var/avalon/dropbox

    chown avalondrop:dropbox /var/avalon/dropbox

    chmod 2775 /var/avalon/dropbox

    setfacl -Rdm g:dropbox:rw /var/avalon/dropbox/

    nano /var/www/avalon/config/browse_everything_providers.yml

Add:

    #
    # To make browse-everything aware of a provider, uncomment the info for that provider and add your API key information.
    # The file_system provider can be a path to any directory on the server where your application is running.
    #
    ---
    file_system:
    #  :home: <%= ENV['HOME'] %>/downloads
      :home: '/var/avalon/dropbox/'
    # dropbox:
    #   :app_key: YOUR_DROPBOX_APP_KEY
    #   :app_secret: YOUR_DROPBOX_APP_SECRET
    # box:
    #   :client_id: YOUR_BOX_CLIENT_ID
    #   :client_secret: YOUR_BOX_CLIENT_SECRET
    # google_drive:
    #   :client_id: YOUR_GOOGLE_API_CLIENT_ID
    #   :client_secret: YOUR_GOOGLE_API_CLIENT_SECRET
    # sky_drive:
    #   :client_id: YOUR_MS_LIVE_CONNECT_CLIENT_ID
    #   :client_secret: YOUR_MS_LIVE_CONNECT_CLIENT_SECRET

Edit /etc/ssh/sshd_config:

    # override default of no subsystems
    #Subsystem      sftp    /usr/libexec/openssh/sftp-server
    Subsystem      sftp    internal-sftp -u 000

    Match Group dropbox
            ChrootDirectory /var/avalon
            ForceCommand internal-sftp -u 000

Restart SSH:

    /etc/init.d/ssh restart

### Batch ingest

To manually start a batch ingest job, run as avalon user:

    su - avalon

    rake avalon:batch:ingest

To make batch ingest run automatically whenever a manifest is present, you need to add a cron job. This cron job can be created by the whenever gem from reading config/schedule.rb. To preview, run:

    whenever

this will translate content in schedule.rb to cron job syntax. Once verified, run the following to write job to crontab:

    whenever --update-crontab

You should get the cron job automatically if you were deploying from Capistrano.

## Manually Restarting the Services

    /etc/init.d/tomcat7 restart
    /etc/init.d/mysql restart
    /etc/init.d/red5 restart
    /etc/init.d/apache2 restart
    /etc/init.d/matterhorn restart
    /etc/init.d/redis-server restart
    /etc/init.d/resque stop
    /etc/init.d/resque start
