# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'

current_dir    = '.'
configs        = File.exists?("#{current_dir}/config.yaml") ? YAML.load_file("#{current_dir}/config.yaml") : { 'configs' => Hash.new }
default_config = configs['configs'].fetch('default', Hash.new)
vagrant_config = default_config.merge(configs['configs'].fetch(ENV['DEV_PROFILE'] ? ENV['DEV_PROFILE'] : configs['configs']['use'], Hash.new))
monitor_count  = vagrant_config['monitors']
readme         = File.dirname(File.expand_path(__FILE__)) + '/VAGRANTUP.md'

Vagrant.configure("2") do |config|

   if File.exists? readme
     config.vm.post_up_message = "********************************************************************************

#{File.read(readme)}

********************************************************************************"
   end

   config.vm.define "linux-dev-workstation"
   config.vm.box = "double16/linux-dev-workstation"

   config.vm.provider :virtualbox do |v, override|
     v.gui = true
     v.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
     v.customize ["modifyvm", :id, "--memory", vagrant_config['memory'] || 4096]
     v.customize ["modifyvm", :id, "--cpus", vagrant_config['cores'] || 2]
     v.customize ["modifyvm", :id, "--vram", "256"]
     v.customize ["setextradata", "global", "GUI/MaxGuestResolution", "any"]
     v.customize ["setextradata", :id, "CustomVideoMode1", "1024x768x32"]
     v.customize ["modifyvm", :id, "--ioapic", "on"]
     v.customize ["modifyvm", :id, "--rtcuseutc", "on"]
     v.customize ["modifyvm", :id, "--accelerate3d", "on"]
     v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
     v.customize ["modifyvm", :id, "--hwvirtex", "on"]
     v.customize ["modifyvm", :id, "--paravirtprovider", "default"]
     if monitor_count
       v.customize ["modifyvm", :id, "--monitorcount", monitor_count]
     end
   end

  ["vmware_fusion", "vmware_workstation"].each do |provider|
    config.vm.provider provider do |v, override|
      v.gui = true
      v.vmx["memsize"] = vagrant_config['memory'] || "4096"
      v.vmx["numvcpus"] = vagrant_config['cores'] || "2"
      v.vmx["cpuid.coresPerSocket"] = "1"
      v.vmx["ethernet0.virtualDev"] = "vmxnet3"
      v.vmx["RemoteDisplay.vnc.enabled"] = "false"
      v.vmx["RemoteDisplay.vnc.port"] = "5900"
      v.vmx["scsi0.virtualDev"] = "lsilogic"
      v.vmx["mks.enable3d"] = "TRUE"
      v.vmx["vhv.enable"] = "TRUE"
      if monitor_count
        v.vmx["svga.numDisplays"] = monitor_count
        v.vmx["svga.autodetect"] = "FALSE"
      end
    end
  end

  config.vm.provider "parallels" do |p, o|
    p.memory = vagrant_config['memory'] || 4096
  end

  config.vm.provider :docker do |docker, override|
    box_version = File.basename(File.dirname(File.dirname(__FILE__)))
    box_version = 'latest' unless box_version.match(/^[0-9][0-9][0-9][0-9]/)
    docker.image = "pdouble16/linux-dev-workstation:#{box_version}"
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
    config.cache.scope = :box
  end

  config.vm.provision "base-bootstrap", type: "shell", inline: <<-SHELL
mkdir -p /etc/facter/facts.d
cat > /etc/facter/facts.d/vagrant.txt <<FACTS
proxy_url=#{vagrant_config['proxy_url'] || ENV['HTTPS_PROXY'] || ENV['HTTP_PROXY']}
http_proxy=#{vagrant_config['proxy_url'] || ENV['HTTP_PROXY']}
https_proxy=#{vagrant_config['proxy_url'] || ENV['HTTPS_PROXY']}
proxy_excludes=#{vagrant_config['proxy_excludes'] || ENV['NO_PROXY']}
ipv4only=#{vagrant_config['ipv4only']}
search_domain=#{vagrant_config['search_domain']}
host_username=#{vagrant_config['username'] || ENV['USER'] || ENV['USERNAME'] || 'vagrant'}
user_name=#{vagrant_config['user_name'] || `git config --get user.name 2>/dev/null`.chomp}
user_email=#{vagrant_config['user_email'] || `git config --get user.email 2>/dev/null`.chomp}
timezone=#{vagrant_config['timezone'] || sprintf("Etc/GMT%+d", Time.now.utc_offset / -3600)}
FACTS

cd /etc/puppetlabs/code
/opt/puppetlabs/bin/puppet apply --hiera_config=/etc/puppetlabs/code/environments/dev/hiera.yaml --modulepath=/etc/puppetlabs/code/environments/dev/modules /etc/puppetlabs/code/environments/dev/manifests/site.pp
  SHELL

end
