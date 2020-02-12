# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'json'
require 'socket'
require 'base64'

Vagrant.require_version ">= 2.1.3"

current_dir    = '.'
box_dir        = File.dirname(File.expand_path(__FILE__))
configs        = File.exist?("#{current_dir}/config.yaml") ? YAML.load_file("#{current_dir}/config.yaml") : { 'configs' => Hash.new }
default_config = configs['configs'].fetch('default', Hash.new)
vagrant_config = default_config.merge(configs['configs'].fetch(ENV['DEV_PROFILE'] ? ENV['DEV_PROFILE'] : configs['configs']['use'], Hash.new))
monitor_count  = vagrant_config['monitors']
readme         = "#{box_dir}/VAGRANTUP.md"

def server_port
  server = TCPServer.new('127.0.0.1', 0)
  port = server.addr[1]
  server.close
  port
end

def configure_rdp_tunnel(config)
  config.trigger.before :ssh do |trigger|
    trigger.name = "Tunnel RDP connection through SSH"
    rdp_port = server_port
    trigger.info = "Connect to desktop via RDP using `localhost:#{rdp_port}`"
    config.ssh.extra_args = ["-L", "#{rdp_port}:localhost:3389"]
  end
end

def configure_sshfs(config)
  if Vagrant.has_plugin?('vagrant-sshfs')
    config.vm.synced_folder ".", "/vagrant", type: "sshfs"
  end
end

def hyperv_network_config(switch_name)
  netip_cmd = "Get-NetIPAddress -InterfaceAlias \"vEthernet (#{switch_name})\" | ConvertTo-JSON"
  dns_cmd = "Get-DnsClientServerAddress | ConvertTo-JSON"
  netip_json = JSON.parse(`powershell.exe -encodedCommand #{Base64.strict_encode64(netip_cmd.encode('utf-16le'))}`)
  dns_json = JSON.parse(`powershell.exe -encodedCommand #{Base64.strict_encode64(dns_cmd.encode('utf-16le'))}`)
  {
    :netip => netip_json['IPAddress'],
    :dns   => dns_json.collect { |e| e['ServerAddresses'] }.flatten.find { |e| e.match(/(?:[0-9]{1,3}\.){3}[0-9]{1,3}/) },
  }
end

Vagrant.configure("2") do |config|

   if File.exist? readme
     config.vm.post_up_message = "********************************************************************************

#{File.read(readme)}

********************************************************************************
Find this file at #{readme}
********************************************************************************"
   end

   config.vagrant.plugins = ["vagrant-cachier"]
   config.vm.define "linux-dev-workstation"

   configure_rdp_tunnel(config)

   config.vm.provider :virtualbox do |v, override|
     override.vagrant.plugins = ['vagrant-cachier', 'vagrant-vbguest', 'vagrant-disksize']

     v.gui = vagrant_config.fetch('native_gui', true)
     v.linked_clone = true if Gem::Version.new(Vagrant::VERSION) >= Gem::Version.new('1.8.0')
     v.customize ["modifyvm", :id, "--memory", vagrant_config['memory'] || 4096]
     v.customize ["modifyvm", :id, "--cpus", vagrant_config['cores'] || 2]
     v.customize ["modifyvm", :id, "--vram", "256"]
     v.customize ["setextradata", "global", "GUI/MaxGuestResolution", "any"]
     v.customize ["setextradata", :id, "CustomVideoMode1", "1024x768x32"]
     v.customize ["modifyvm", :id, "--ioapic", "on"]
     v.customize ["modifyvm", :id, "--rtcuseutc", "on"]
#     v.customize ["modifyvm", :id, "--accelerate3d", "on"]
     v.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
     v.customize ["modifyvm", :id, "--clipboard-mode", "bidirectional"]
     v.customize ["modifyvm", :id, "--draganddrop", "bidirectional"]
     v.customize ["modifyvm", :id, "--hwvirtex", "on"]
     v.customize ["modifyvm", :id, "--nested-hw-virt", "on"]
     v.customize ["modifyvm", :id, "--paravirtprovider", "default"]
     if monitor_count
       v.customize ["modifyvm", :id, "--monitorcount", monitor_count]
     end
   end

  ["vmware_fusion", "vmware_workstation"].each do |provider|
    config.vm.provider provider do |v, override|
      v.gui = vagrant_config.fetch('native_gui', true)
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

  config.vm.provider "hyperv" do |h, o|
    # dnf breaks when using SMB mounts
    if Vagrant.has_plugin?("vagrant-cachier")
      config.cache.auto_detect = false
    end
    h.cpus = vagrant_config['cores'] || "2"
    h.linked_clone = true
    h.maxmemory = vagrant_config['memory'] || "4096"
    h.memory = "2048"
    o.trigger.before [ :up, :resume, :reload, :provision ] do |trigger|
      trigger.info = "Start DHCP Server"
      trigger.ruby do |env, machine|
        nc = hyperv_network_config('VagrantSwitch')
        puts "Starting DHCP server on #{nc[:netip]}, DNS #{nc[:dns]}"
        spawn(RbConfig.ruby, "#{box_dir}/rdhcpd.rb", nc[:netip], nc[:dns])
      end
    end
    o.trigger.after [ :halt, :suspend, :destroy ] do |trigger|
      trigger.info = "Stop DHCP Server"
      trigger.ruby do |env, machine|
        spawn(RbConfig.ruby, "#{box_dir}/rdhcpd.rb", 'stop')
      end
    end
  end

  config.vm.provider :docker do |docker, override|
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

    if Gem.win_platform?
      # "Docker for Windows" translates volumes[] paths into Windows style paths
      docker.create_args = ['--privileged', '-v', '/var/run/docker.sock:/var/run/docker.sock']
    else #if File.exist?('/var/run/docker.sock')
      docker.volumes = ['/var/run/docker.sock:/var/run/docker.sock']
    end

    override.vm.network :forwarded_port, guest: 22, host: 2222, host_ip: "0.0.0.0", id: "ssh", auto_correct: true
    override.ssh.proxy_command = "docker run -i --rm --name linux-dev-workstation-tunnel --link linux-dev-workstation alpine/socat - TCP:linux-dev-workstation:22,retry=3,interval=2"
  end

  config.vm.provider :aws do |aws, override|
    override.vagrant.plugins = ["vagrant-sshfs"]
    configure_sshfs(override)
    override.ssh.username = "fedora"
  end

  config.vm.provider :azure do |azure, override|
    override.vagrant.plugins = ["vagrant-sshfs"]
    configure_sshfs(override)
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  end

  # swap is required for proper memory management
  # if the provider doesn't allocate swap add a small swapfile
  config.vm.provision "swapfile", type: "shell", inline: <<-SHELL
    is_running_in_container() {
      awk -F: '$3 ~ /^\\/$/{ c=1 } END { exit c }' /proc/self/cgroup
    }
    if ! is_running_in_container && [ -z "$(/usr/sbin/swapon --show=size --bytes --noheadings)" ]; then
      if [ ! -s /swapfile ]; then
        echo "Creating 128M swap space in /swapfile..."
        dd if=/dev/zero of=/swapfile bs=1M count=128
        chown root:root /swapfile
        chmod 0600 /swapfile
        mkswap /swapfile
      fi
      echo "Turning the swapfile on..."
      swapon /swapfile
      if ! grep -q /swapfile /etc/fstab; then
        echo "Adding swap entry to /etc/fstab"
        echo "\n/swapfile none            swap    sw              0       0" >> /etc/fstab
      fi
    fi
  SHELL

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
theme=#{vagrant_config['theme']}
shell=#{vagrant_config['shell']}
native_gui=#{vagrant_config['native_gui']}
resolution=#{vagrant_config['resolution']}
FACTS

[ -x /usr/local/sbin/disksize.sh ] && /usr/local/sbin/disksize.sh

cd /etc/puppetlabs/code
/opt/puppetlabs/bin/puppet apply --hiera_config=/etc/puppetlabs/code/environments/dev/hiera.yaml --modulepath=/etc/puppetlabs/code/environments/dev/modules /etc/puppetlabs/code/environments/dev/manifests/site.pp
  SHELL

end
