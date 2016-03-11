# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  (1..3).each do |node|
    config.vm.define "node#{node}" do |config|
      config.vm.box = "bento/centos-7.1"
      config.vm.hostname = "node#{node}"
      config.vm.network :private_network, ip: "192.168.99.10#{node}"
      config.ssh.insert_key = false
      #config.ssh.port = (2021 + node)
      config.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--memory", "2048", "--ioapic", "on", "--cpus", "2"]
      end
    end
  end

end
