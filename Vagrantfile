# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "bento/centos-7.2"

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

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

  config.vm.provider "virtualbox" do |vb|
    # Validate this should be run it once
    if ARGV[0] == "up" && ! File.exist?("./disk1.vdi")
      vb.customize [
        'createhd',
        '--filename', "./disk1.vdi",
        '--format', 'VDI',
        # 20GB
        '--size', 20 * 1024
      ]

      vb.customize [
        'storageattach', :id,
        '--storagectl', 'SATA Controller',
        '--port', 1, '--device', 0,
        '--type', 'hdd', '--medium',
#        file_to_disk
      ]
    end

    if ARGV[0] == "up" && ! File.exist?("./disk1.vdi")
      # Run script to map new disk
      config.vm.provision "shell", inline: <<-SHELL
pvcreate /dev/sdb
vgextend VolGroup /dev/sdb
lvextend /dev/VolGroup/lv_root /dev/sdb
resize2fs /dev/VolGroup/lv_root
  SHELL
    end
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
