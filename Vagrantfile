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
  config.vbguest.no_install = true
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

  config.vm.provision "shell", env: {"HTTP_PROXY" => ENV["HTTP_PROXY"], "HTTPS_PROXY" => ENV["HTTPS_PROXY"], "NO_PROXY" => ENV["NO_PROXY"] }, inline: <<-SHELL
    if [ -n "${HTTP_PROXY}" ]; then
      grep -q "proxy=" /etc/yum.conf || echo "proxy=${HTTP_PROXY}" >> /etc/yum.conf
      grep -q "ip_resolve=4" /etc/yum.conf || echo "ip_resolve=4" >> /etc/yum.conf
      grep -q "http_proxy=" /etc/environment || echo "http_proxy=\"${HTTP_PROXY}\"" >> /etc/environment

      if [ -n "${HTTPS_PROXY}" ]; then
        grep -q "https_proxy=" /etc/environment || echo "https_proxy=\"${HTTPS_PROXY}\"" >> /etc/environment
      fi

      if [ -n "${NO_PROXY}" ]; then
        grep -q "no_proxy=" /etc/environment || echo "no_proxy=\"${NO_PROXY}\"" >> /etc/environment
      fi
    fi

    [ -f /opt/puppetlabs/puppet/bin/puppet ] || (
      yum install -y deltarpm
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
