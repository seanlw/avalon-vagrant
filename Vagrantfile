# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

	config.vm.hostname = "avalon"

	config.vm.box = "ubuntu/xenial64"

	config.vm.network :forwarded_port, guest: 80, host: 8888 # Avalon
	config.vm.network :forwarded_port, guest: 8181, host: 8181 # Nginx HLS Stream
	config.vm.network :forwarded_port, guest: 8080, host: 8080 # Matterhorn
	config.vm.network :forwarded_port, guest: 8983, host: 8983 # Solr
	config.vm.network :forwarded_port, guest: 8984, host: 8984 # Fedora 4

	config.vm.provider "virtualbox" do |v|
		v.memory = 3072
	end

	config.vm.synced_folder "./dropbox", "/var/avalon/dropbox",
		create: true,
		mount_options: ["dmode=777,fmode=777"]

	shared_dir = "/vagrant"

	config.vm.provision "shell", path: "./install_scripts/bootstrap.sh", args: shared_dir
	config.vm.provision "shell", path: "./install_scripts/nginx.sh", args: shared_dir
	config.vm.provision "shell", path: "./install_scripts/fedora4.sh", args: shared_dir
	config.vm.provision "shell", path: "./install_scripts/solr.sh", args: shared_dir
	config.vm.provision "shell", path: "./install_scripts/matterhorn.sh", args: shared_dir
	config.vm.provision "shell", path: "./install_scripts/passenger.sh", args: shared_dir
	config.vm.provision "shell", path: "./install_scripts/avalon.sh", args: shared_dir

end
