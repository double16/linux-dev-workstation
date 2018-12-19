# Configuration

Your development box has been created. If you do not have a graphical desktop restart the box using the following command. (Cloud providers such as AWS see below for VNC instructions.)

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
        # Limit DNS resolution to IPV4
        ipv4only: true
        # Populates git config
        user_name: Droopy Dog
        user_email: droppy@dogpound.nil
        # Set the number of monitors, defaults to let the provider determine it
        monitors: 1
        # Optional Timezone, pulled from host machine if not specified
        timezone: America/Chicago
        # Solarized theme selection: 'light', 'dark', 'none' or not specified. Not specifying will
        # initialize to 'light' but not change it afterwards.
        theme: light
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

## AWS, Azure

Running the box on the cloud provides a VNC server. You need to use SSH tunneling to access the server. The `vagrant ssh` command will forward an unused port to the VNC server. Assuming you have `vncviewer` installed with either the TightVNC or TigerVNC package:

```shell
$ vagrant ssh
==> default: Running triggers before ssh ...
==> default: Running trigger: Tunnel VNC connection through SSH...
==> default: Connect to desktop via VNC using `vncviewer localhost:50841`
----------------------------------------------------------------
  CentOS 7.5.1804                             built 2018-08-01
----------------------------------------------------------------
[centos@xxxxx ~]$
$ vncviewer localhost:50841
```

If you want to use a different VNC client, point it to the equivalent of `localhost:50841` in the output above.

_DO NOT_ expose port 5900 by adjusting firewall rules. The VNC server has no password. If you want direct access to VNC then you must change the VNC configuration. SSH tunneling is preferred.

Sometimes after starting a new EC2 instance, the IP and hostname will be changed while it is running. It seems the VNC systemctl service doesn't handle this well and VNC won't be started. Restart the EC2 instance to fix it.

## Docker

Running the box as a container is similar to using a cloud provider. You use an SSH tunnel and VNC viewer. SSH authentication is a little different, by default it uses the Vagrant insecure SSH key. If you want to use a different SSH key, set the environment variable `SSH_AUTHORIZED_KEYS` with the content of your public key(s). The image is based on https://github.com/jdeathe/centos-ssh, the various SSH options should work with this image.

Vagrant can bring up the box using Docker and supports most of the common Vagrant features. If you want to run the image directly with Docker, it will look similar to the following:

```shell
$ docker run -d -p 2020:22 pdouble16/linux-dev-workstation
$ curl -LSs https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant > id_rsa_insecure
$ chmod 600 id_rsa_insecure
$ ssh -t -L 5910:localhost:5900 -i id_rsa_insecure -p 2020 vagrant@{docker-host-ip}
$ vncviewer localhost:5910
```

If you want to control the hosting Docker daemon from inside the container (this is the default when running using Vagrant):

```shell
$ docker run -d -p 2020:22 -v /var/run/docker.sock:/var/run/docker.sock pdouble16/linux-dev-workstation
```

If you want to run Docker in the container without using the host Docker daemon, you need to run with privileged mode:

```shell
$ docker run --privileged -d -p 2020:22 pdouble16/linux-dev-workstation
```

## Kubernetes

~~`kubectl` and `microk8s` are installed. `microk8s.kubectl`, `microk8s.docker` and `microk8s.istioctl` are aliased to commands without the `microk8s.` prefix. `microk8s` is a snap application and is difficult to run under Docker. In the Docker container,~~ `minikube` is installed and defaults to use the Docker daemon. It must be run using `sudo`:

```shell
$ sudo minikube start
```

## Hyper-V

Vagrant networking support for Hyper-V isn't as complete as VirtualBox or VMware. There are some extra steps necessary to get an IP address for the box. Hyper-V requires running Vagrant as administrator. Using PowerShell as administrator, execute the following:

```powershell
PS > vagrant up --provider hyperv   # this may fail, that's ok for now
PS > ${HOME}\.vagrant.d\boxes\linux-dev-workstation\_version_\hyperv\create-natswitch.ps1  # ignore errors, these are from detecting existing networking
PS > vagrant reload
```

To see the GUI:

1. Open "Hyper-V Manager"
2. Click the local machine in the left panel
3. Click the virtual machine created by Vagrant
4. Click "Connect..." in the right bottom panel

### Display Resolution

Display resolution is fixed in the VM at boot time. It can be set by running the following commands:

```shell
$ grubby --update-kernel=ALL --args="video=hyperv_fb:1440x1024"
```
