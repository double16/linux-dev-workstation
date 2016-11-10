# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.2"

  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # config.vm.synced_folder "../data", "/vagrant_data"

  # Increase memory for Parallels Desktop
  config.vm.provider "parallels" do |p, o|
    p.memory = "4096"
  end

  # Increase memory for Virtualbox
  #config.vbguest.no_install = true
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.cpus = 2
    vb.memory = "4096"
  end

  # Increase memory for VMware
  ["vmware_fusion", "vmware_workstation"].each do |p|
    config.vm.provider p do |v|
      v.gui = true
      v.vmx["numvcpus"] = "2"
      v.vmx["memsize"] = "4096"
    end
  end

  config.vm.provision "shell", inline: <<-SHELL
    which deltarpm || yum install -y deltarpm
    which puppet || (
      rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
      yum install -y puppet-agent
    )
  SHELL

  config.vm.provision "puppet" do |puppet|
    puppet.environment_path = "environments"
    puppet.environment = "dev"
    puppet.options = "--debug"
  end

end
