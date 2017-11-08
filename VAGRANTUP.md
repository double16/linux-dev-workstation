Your development box has been created. Likely you will not have a graphical desktop at this point. Restart the box using the following command and you should see a graphical desktop. (Cloud providers such as AWS see below for VNC instructions.)

  vagrant reload

There are several ways to configure the box for your environment. To apply configuration changes, run the following command:

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
    proxied:
        memory: 4096
        cores: 2
        # Proxy URL that will be configured in various places
        proxy_url: http://proxy:8123
        # Domains excluded from the proxy, comma separated list
        proxy_excludes: .internal.net,.dmz.net
        # Limit DNS resolution to IPV4
        ipv4only: true
        # Force search domain in /etc/resolv.conf
        search_domain: company.com
```

## Proxies
The variables `HTTP_PROXY`, `HTTPS_PROXY` and `NO_PROXY` are recognized and applied throughout the box. If you want to use something different, the `config.yaml` file can be used to override the environment variables.

## SSH Keys
Any SSH public/private key pairs found in the `/vagrant` guest directory, which is usually mapped to the directory containing the `Vagrantfile`, will be searched for SSH keys. Any files ending with `.pub` are found and if there is a matching file without `.pub`, the key will be added as an identity in SSH. The SSH config points to the `/vagrant` directory, so if this directory is unmounted the keys will not be found. SSH usually handles missing files gracefully. Important exclusions to the search path are the `environments` directory and any directory beginning with a `.`.

## SSH User
The `vagrant` user is the primary user on the box. SSH will be configured to use the host machine user account. The environment variables `USER` and `USERNAME` are checked. The profile in `config.yaml` may include a `username` value to specify the user name.

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

## AWS
Running the box on AWS provides a VNC server. You need to use SSH tunneling to access the server. Assuming you have `vncviewer` installed with either the TightVNC or TigerVNC package:

```shell
$ ssh -t -L 5900:localhost:5900 vagrant@ec2-NNN.amazonaws.com
$ vncviewer localhost:5900
```

If you want to use a different VNC client, point it to `localhost:5900`.

_DO NOT_ expose port 5900 by adjusting firewall rules. The VNC server has no password. If you want direct access to VNC then you must change the VNC configuration. SSH tunneling is preferred.
