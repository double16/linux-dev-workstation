# Configuration

Your development box has been created. If you do not have a graphical desktop restart the box using the following command. (Cloud providers such as AWS see below for RDP instructions.)

  vagrant reload

There are several ways to configure the box for your environment. After making configuration changes detailed below, run the following command:

  vagrant provision

The `config.yaml` file has several machine size configurations. The default is medium, you can change that by changing the `use` entry in `config.yaml` or setting the environment variable `DEV_PROFILE` to the configuration name. Using the environment variable will allow you to commit the `config.yaml` file to a shared repository.

```yaml
---
configs:
    use: 'medium'
    small:
        memory: 2048
        cores: 2
    medium:
        memory: 4096
        cores: 2
    large:
        memory: 8192
        cores: 4
    # settings in 'default' are applied to all configurations
    default:
        # Proxy URL that will be configured in various places
        proxy_url: http://proxy:8123
        # Domains excluded from the proxy, comma separated list
        proxy_excludes: .internal.net,.dmz.net
        # Limit DNS resolution to IPV4
        ipv4only: true
        # Force search domain in /etc/resolv.conf
        search_domain: company.com
        # Populates git config
        user_name: Droopy Dog
        user_email: droppy@dogpound.nil
        # Set the number of monitors, defaults to let the provider determine it. Not necessary when using RDP.
        monitors: 1
        # Use the Hypervisor's GUI to login in addition to RDP
        native_gui: true
        # Configure display resolution on startup, useful for providers that do not automatically resize. Not necessary when using RDP.
        resolution: 1440x1024
        # Optional Timezone, pulled from host machine if not specified
        timezone: America/Chicago
        # Solarized theme selection: 'light', 'dark', 'none' or not specified. Not specifying will
        # initialize to 'light' but not change it afterwards.
        theme: light
        # default shell: bash, zsh
        shell: bash
```

## Proxies

The variables `HTTP_PROXY`, `HTTPS_PROXY` and `NO_PROXY` are recognized and applied throughout the box. If you want to use something different, the `config.yaml` file can be used to override the environment variables.

## SSH Keys

Any SSH public/private key pairs found in the `/vagrant` guest directory, which is usually mapped to the directory containing the `Vagrantfile`, will be searched for SSH keys. Any files ending with `.pub` are found and if there is a matching file without `.pub`, the key will be added as an identity in SSH. The SSH config points to the `/vagrant` directory, so if this directory is unmounted the keys will not be found. SSH usually handles missing files gracefully. Important exclusions to the search path are the `environments` directory and any directory beginning with a `.`.

## SSH User

The `vagrant` user is the primary user on the box. SSH will be configured to use the host machine user account. The environment variables `USER` and `USERNAME` are checked. The profile in `config.yaml` may include a `username` value to specify the user name.

## Git User

If the host computer has defined a name and email for git commits, git will be configured in the box the same way. The name and email for commits can be specified in `config.yaml` using `user_name` and `user_email` keys. See example above.

## CA Certificates

CA certificates can be added to the system wide trust store by placing the files similarly to the above SSH keys. The files must be in PEM format and have an extension of `.pem`, `.crt` or `.cer`.

## Source Code Repositories

You can configure source code repositories to be checked out as part of provisioning. The puppet module at https://forge.puppet.com/puppetlabs/vcsrepo is used for checking out and it supports several versioning systems. The repo information is stored in `repos.yaml` in the root of this repo. Each repo has a name which is checked out into `/home/vagrant/Workspace`, and the keys under it specify the source URL, branch, etc.

```yaml
---
spring-boot:
  provider: git
  source: https://github.com/spring-projects/spring-boot.git
  revision: 1.5.x

qgroundcontrol:
  provider: git
  source: https://github.com/mavlink/qgroundcontrol.git
```

## Disk Size

Increasing disk size can be done fairly easily. There are two steps: increase the virtual disk size, then grow the filesystem to use the additional space.

### Increase the Virtual Disk Size

The method to increase the disk size depends on the provider. VirtualBox has a Virtual Media Manager in the UI. You can also use the `vagrant-disksize` plugin by adding the following to your `Vagrantfile`. `vagrant up` will then handle the disk size increase.

```Vagrantfile
  if Vagrant.has_plugin?("vagrant-disksize")
    config.disksize.size = '200GB'
  end
```

### Grow the Filesystem

There is a script at `/usr/local/sbin/disksize.sh` in the box that will grow the filesystem online, i.e. it is run while the box is running and doesn't require a restart. It is safe to run at any time and won't do anything if it can't find free space. Provisioning runs this script, so `vagrant provision` will run it. If you use the `vagrant-disksize` described above, all will be handled for you.

## AWS, Azure

Running the box on the cloud provides a RDP server. You need to use SSH tunneling to access the server. The `vagrant ssh` command will forward an unused port to the RDP server.

```shell
$ vagrant ssh
==> default: Running triggers before ssh ...
==> default: Running trigger: Tunnel RDP connection through SSH...
==> default: Connect to desktop via RDP using `localhost:50841`
----------------------------------------------------------------
  Fedora 32                                     built 2020-06-08
----------------------------------------------------------------
[fedora@xxxxx ~]$
```

Point your RDP client to the equivalent of `localhost:50841` in the output above.

_DO NOT_ expose port 3389 by adjusting firewall rules. The RDP server has an insecure password. If you want direct access to RDP then you must change the vagrant user password. SSH tunneling is preferred.

## Hyper-V

Vagrant networking support for Hyper-V isn't as complete as VirtualBox or VMware. There are some extra steps necessary to get an IP address for the box. Hyper-V requires running Vagrant as administrator. Using PowerShell as administrator, execute the following:

```powershell
PS > vagrant up --provider hyperv   # this may fail, that's ok for now
PS > ${HOME}\.vagrant.d\boxes\linux-dev-workstation\_version_\hyperv\create-natswitch.ps1  # ignore errors, these are from detecting existing networking
PS > vagrant reload
```

When prompted for the networking switch, choose `VagrantSwitch`.

Follow the instructions above for cloud providers to connect using RDP. RDP provides a better experience than using the Hyper-V console.

## Docker

Running the box as a container is similar to using a cloud provider. You use an SSH tunnel and RDP viewer. SSH authentication is a little different, by default it uses the Vagrant insecure SSH key. If you want to use a different SSH key, set the environment variable `SSH_AUTHORIZED_KEYS` with the content of your public key(s). The image is based on https://github.com/pdouble16/fedora-ssh, the various SSH options should work with this image.

You will need to set the vagrant user password before connecting with RDP.

```shell
$ vagrant up --provider docker
$ vagrant ssh
$ sudo passwd vagrant
New password:
New password again:
```

Vagrant can bring up the box using Docker and supports most of the common Vagrant features. If you want to run the image directly with Docker, it will look similar to the following:

```shell
$ docker run -d -p 2020:22 pdouble16/linux-dev-workstation
$ curl -LSs https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant > id_rsa_insecure
$ chmod 600 id_rsa_insecure
$ ssh -t -L 13389:localhost:3389 -i id_rsa_insecure -p 2020 vagrant@{docker-host-ip}
$ [rdp client] localhost:13389
```

If you want to control the hosting Docker daemon from inside the container (this is the default when running using Vagrant):

```shell
$ docker run -d -p 2020:22 -v /var/run/docker.sock:/var/run/docker.sock pdouble16/linux-dev-workstation
```

If you want to run Docker in the container without using the host Docker daemon, you need to run with privileged mode:

```shell
$ docker run --privileged -d -p 2020:22 pdouble16/linux-dev-workstation
```

### Home Directory on Persistent Volume

The home directory `/home/vagrant` can be stored on a Docker volume and eases upgrading. You will need to use `docker volume create` before bringing up the box. Add the following to your Vagrantfile to mount the volume to `/home/vagrant`. The initial run will populate the volume with `/home/vagrant`.

```shell
$ docker create volume ldv_home
```

```ruby
  config.vm.provider :docker do |docker, override|
    docker.create_args = ['-v', 'ldv_home:/home/vagrant']
  end
```

## Kubernetes

[k3s](https://k3s.io) is installed in the recommended way. The Docker container has the `k3s` binary installed but no attempt has been made to have it running out of the box.

## Display Resolution

Display resolution is fixed in the VM at boot time. It can be set by configuring the `resolution` property in `config.yaml`. This isn't necessary when connecting using RDP, the connection will use the resolution specified in the RDP configuration.
