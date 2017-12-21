# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

current_dir    = File.dirname(File.expand_path(__FILE__))
configs        = YAML.load_file("#{current_dir}/config.yaml")
default_config = configs['configs'].fetch('default', Hash.new)
vagrant_config = default_config.merge(configs['configs'][ENV['DEV_PROFILE'] ? ENV['DEV_PROFILE'] : configs['configs']['use']])

Vagrant.configure("2") do |config|
  # This trick is used to prefer a VM box over docker
  config.vm.provider "virtualbox"
  config.vm.provider "vmware_fusion"

  if ENV['VAGRANT_FROM_SCRATCH']
    config.vm.box = "bento/centos-7.4"
  else
    config.vm.box = "double16/linux-dev-workstation"
  end
  config.vm.provider :docker do |docker, override|
    override.vm.box = nil
    override.vm.allowed_synced_folder_types = :rsync if ENV.has_key?('CIRCLECI')
    docker.image = "jdeathe/centos-ssh:centos-7-2.2.4"
    docker.name = "linux-dev-workstation"
    docker.remains_running = true
    docker.has_ssh = true
    docker.env = {
      :SSH_USER => 'vagrant',
      :SSH_SUDO => 'ALL=(ALL) NOPASSWD:ALL',
      :LANG     => 'en_US.UTF-8',
      :LANGUAGE => 'en_US:en',
      :LC_ALL   => 'en_US.UTF-8',
      :SSH_INHERIT_ENVIRONMENT => 'true',
    }
    override.ssh.proxy_command = "docker run -i --rm --link linux-dev-workstation alpine/socat - TCP:linux-dev-workstation:22,retry=3,interval=2"
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :machine
  end

  # Increase memory for Parallels Desktop
  config.vm.provider "parallels" do |p, o|
    p.memory = vagrant_config['memory']
  end

  # Increase memory for Virtualbox
  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.no_install = true
  end
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.cpus = vagrant_config['cores']
    vb.memory = vagrant_config['memory']
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--paravirtprovider", "default"]
  end

  config.vm.provider "virtualbox" do |vb|
    # Validate this should be run it once
    if ARGV[0] == "upX" && ! File.exist?("./disk1.vdi")
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

    if ARGV[0] == "upX" && ! File.exist?("./disk1.vdi")
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
      v.vmx["numvcpus"] = vagrant_config['cores']
      v.vmx["memsize"] = vagrant_config['memory']
      v.vmx["vhv.enable"] = "TRUE"
    end
  end

  config.vm.provision "bootstrap", type: "shell", env: {"HTTP_PROXY" => vagrant_config['proxy_url'] || ENV["HTTP_PROXY"], "HTTPS_PROXY" => vagrant_config['proxy_url'] || ENV["HTTPS_PROXY"], "NO_PROXY" => vagrant_config['proxy_excludes'] || ENV["NO_PROXY"] }, inline: <<-SHELL

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

    [ -x /usr/bin/makedeltarpm ] || yum install -y deltarpm

    locale -a | grep -qi en_US || (
        yum reinstall -y glibc-common
        localedef -i en_US -f UTF-8 en_US.UTF-8
        echo "LANG=en_US.UTF-8" > /etc/locale.conf
        echo "LANG=en_US.UTF-8" > /etc/sysconfig/i18n
    )

    [ -f /var/lib/vagrant-yum-update ] || (
      touch /var/lib/vagrant-yum-update
      yum update -y
    )

    [ -f /opt/puppetlabs/puppet/bin/puppet ] || (
      rpm -Uvh https://yum.puppetlabs.com/puppetlabs-release-pc1-el-7.noarch.rpm
      yum install -y puppet-agent
    )
  SHELL

  config.vm.provision "puppet", type: "puppet" do |puppet|
    puppet.environment_path = "environments"
    puppet.environment = "dev"
    puppet.facter = {
      "proxy_url" => vagrant_config['proxy_url'] || ENV["HTTPS_PROXY"] || ENV["HTTP_PROXY"],
      "http_proxy" => vagrant_config['proxy_url'] || ENV["HTTP_PROXY"],
      "https_proxy" => vagrant_config['proxy_url'] || ENV["HTTPS_PROXY"],
      "proxy_excludes" => vagrant_config['proxy_excludes'] || ENV["NO_PROXY"],
      "ipv4only" => vagrant_config['ipv4only'],
      "search_domain" => vagrant_config['search_domain'],
      "host_username" => vagrant_config['username'] || ENV['USER'] || ENV['USERNAME'] || 'vagrant',
      "user_name" => vagrant_config['user_name'] || `git config --get user.name 2>/dev/null`.chomp,
      "user_email" => vagrant_config['user_email'] || `git config --get user.email 2>/dev/null`.chomp,
      "timezone" => vagrant_config['timezone'] || sprintf("Etc/GMT%+d", Time.now.utc_offset / -3600),
    }
#    puppet.options = "--debug"
#    puppet.options = "--noop"
  end

end
