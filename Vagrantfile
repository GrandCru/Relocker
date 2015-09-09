# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|

  config.vm.box = "ubuntu/trusty64"

  config.vm.network "forwarded_port", guest: 6379, host: 6379

  config.vm.network "private_network", ip: "192.168.33.11"

  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update
    sudo apt-get -y install redis-server
    sudo sed -i 's/bind/#bind/g' /etc/redis/redis.conf
    sudo service redis-server restart
  SHELL

end
