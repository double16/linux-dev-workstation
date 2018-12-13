# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'yaml'
require 'socket'

Vagrant.require_version ">= 2.1.3"

current_dir    = File.dirname(File.expand_path(__FILE__))
box_dir        = current_dir
configs        = YAML.load_file("#{current_dir}/config.yaml")
default_config = configs['configs'].fetch('default', Hash.new)
vagrant_config = default_config.merge(configs['configs'][ENV['DEV_PROFILE'] ? ENV['DEV_PROFILE'] : configs['configs']['use']])
monitor_count  = vagrant_config['monitors']

def server_port
  server = TCPServer.new('127.0.0.1', 0)
  port = server.addr[1]
  server.close
  port
end

def configure_vnc_tunnel(config)
  config.trigger.before :ssh do |trigger|
    trigger.name = "Tunnel VNC connection through SSH"
    vnc_port = server_port
    trigger.info = "Connect to desktop via VNC using `vncviewer localhost:#{vnc_port}`"
    config.ssh.extra_args = ["-L", "#{vnc_port}:localhost:5900"]
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

def validate_pid_f(pid_f)
  return false unless File.exist?(pid_f)
  pid = File.read(pid_f)
  begin
    Process.kill(0, pid.to_i)
    true
  rescue
    File.delete(pid_f)
    false
  end
end

Vagrant.configure("2") do |config|
  # This trick is used to prefer a VM box over docker
  config.vm.provider "virtualbox"
  config.vm.provider "vmware_fusion"

  config.vagrant.plugins = ["vagrant-cachier"]

  if ENV['VAGRANT_FROM_SCRATCH']
    config.vm.box = "bento/centos-7.5"
  else
    config.vm.box = "double16/linux-dev-workstation"
  end
  config.vm.provider :docker do |docker, override|
    configure_vnc_tunnel(override)
    override.vm.box = nil
    override.vm.allowed_synced_folder_types = :rsync if ENV.has_key?('CIRCLECI')
    docker.image = "jdeathe/centos-ssh:centos-7-2.3.2"
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
    override.ssh.proxy_command = "docker run -i --rm --name linux-dev-workstation-tunnel --link linux-dev-workstation alpine/socat - TCP:linux-dev-workstation:22,retry=3,interval=2"
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :machine
  end

  config.vm.provider "parallels" do |p, o|
    p.memory = vagrant_config['memory']
  end

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.no_install = true
  end
  config.vm.provider "virtualbox" do |vb|
    vb.gui = true
    vb.cpus = vagrant_config['cores']
    vb.memory = vagrant_config['memory']
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--paravirtprovider", "default"]
    if monitor_count
      vb.customize ["modifyvm", :id, "--monitorcount", monitor_count]
    end
  end

  ["vmware_fusion", "vmware_workstation"].each do |p|
    config.vm.provider p do |v|
      v.gui = true
      v.vmx["numvcpus"] = vagrant_config['cores']
      v.vmx["memsize"] = vagrant_config['memory']
      v.vmx["vhv.enable"] = "TRUE"
      if monitor_count
        v.vmx["svga.numDisplays"] = monitor_count
        v.vmx["svga.autodetect"] = "FALSE"
      end
    end
  end

  config.vm.provider "hyperv" do |h, o|
    h.cpus = vagrant_config['cores'] || "2"
    h.linked_clone = true
    h.maxmemory = vagrant_config['memory'] || "4096"
    o.trigger.before [ :up, :resume, :reload ] do |trigger|
      trigger.info = "Start DHCP Server"
      trigger.ruby do |env, machine| do
        unless validate_pid_f(rdhcpd_pid_f)
          nc = hyperv_network_config('VagrantSwitch')
          puts "Starting DHCP server on #{nc[:netip]}, DNS #{nc[:dns]}"
          dhcpd_pid = spawn(RbConfig.ruby, "#{box_dir}/rdhcpd.rb", nc[:netip], nc[:dns])
          File.open(rdhcpd_pid_f, 'w') { |f| f.write(dhcpd_pid.to_s) }
        end
      end
    end
    o.trigger.after [ :halt, :destroy ] do |trigger|
      trigger.info = "Stop DHCP Server"
      trigger.ruby do |env, machine| do
        if validate_pid_f(rdhcpd_pid_f)
          dhcpd_pid = File.read(rdhcpd_pid_f)
          File.delete(rdhcpd_pid_f)
          Process.kill("KILL", dhcpd_pid.to_i)
        end
      end
    end
  end

  # swap is required for propery memory management
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

    # Cannot update kernel on VirtualBox 5.x due to incompatible video driver
    yum install -y kernel-headers kernel-devel kernel-devel-uname-r
    grep -q "exclude=kernel" /etc/yum.conf || echo "exclude=kernel*" >> /etc/yum.conf

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
      rpm -Uvh https://yum.puppet.com/puppet5/puppet5-release-el-7.noarch.rpm
      yum install -y puppet-agent-5.5.1-1.el7.x86_64
      mkdir -p /etc/puppetlabs/facter/facts.d
    )
  SHELL

  config.vm.provision "puppet", type: "puppet" do |puppet|
    puppet.environment_path = "environments"
    puppet.environment = "dev"
    puppet.environment_variables = {
      'NODE_BUILD_CACHE_PATH' => '/tmp/vagrant-cache/nodenv',
      'RUBY_BUILD_CACHE_PATH' => '/tmp/vagrant-cache/rbenv',
    }
    puppet.working_directory = "/tmp/vagrant-puppet"
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
      "theme" => vagrant_config['theme'],
    }
#    puppet.options = "--debug"
#    puppet.options = "--noop"
  end

end
