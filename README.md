# Linux Java/DevOps Workstation

This Vagrant image contains a developer workspace with the following software:

* CentOS 7.4
* Java 8
* Java 9
* IntelliJ IDEA Ultimate + sundry plugins
* NetBeans
* vim 8, gvim, sundry vim plugins
* git
* svn
* Docker, Docker Compose, Kitematic
* Python 2
* asciidoc
* nodenv (NodeJS environments)
* rbenv (Ruby Environments)
* Maven
* Ansible
* Puppet
* Slack
* HipChat
* Xfce Desktop
* Firefox
* Chrome
* VirtualBox
* Vagrant
* R, RStudio
* sdkman
* Groovy via sdkman
* Gradle via sdkman
* Grails via sdkman
* packer
* consul
* vault

## Configure
The `config.yaml` file has several machine size configurations. The default is medium, you can change that by changing the `use` entry in `config.yaml`.

### SSH Keys
Any SSH public/private key pairs found in the `/vagrant` guest directory, which is usually mapped to the directory containing the `Vagrantfile`, will be searched for SSH keys. Any files ending with `.pub` are found and if there is a matching file without `.pub`, the key will be added as an identity in SSH. The SSH config points to the `/vagrant` directory, so if this directory is unmounted the keys will not be found. SSH usually handles missing files gracefully. Important exclusions to the search path are the `environments` directory and any directory beginning with a `.`.

### CA Certificates
CA certificates can be added to the system wide trust store by placing the files similarly to the above SSH keys. The files must be in PEM format and have an extension of `.pem`, `.crt` or `.cer`.

### Source Code Repositories
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

## Installation

It is recommended to enable caching of OS packages using the `vagrant-cachier` plugin.
```shell
$ vagrant plugin install vagrant-cachier
```

If you are using VirtualBox, the `vagrant-vbguest` plugin is recommended to maintain the guest additions at the same level as your VirtualBox install.
```shell
$ vagrant plugin install vagrant-vbguest
```

Finally, vagrant up:
```shell
$ vagrant up
```

## Updates

Keeping this box up to date is easy. There is no need to re-create the box when there is a new download on vagrantcloud.com. The box uses Puppet to do provisioning both with Packer and Vagrant. The following commands will give you the latest:

```shell
$ git pull
$ vagrant provision
```

## AWS

Running the box on AWS provides a VNC server. You need to use SSH tunneling to access the server. Assuming you have `vncviewer` installed with either the TightVNC or TigerVNC package:

```shell
$ ssh -t -L 5900:localhost:5900 vagrant@ec2-NNN.amazonaws.com
$ vncviewer localhost:5900
```

If you want to use a different VNC client, point it to `localhost:5900`.

_DO NOT_ expose port 5900 by adjusting firewall rules. The VNC server has no password. If you want direct access to VNC then you must change the VNC configuration. SSH tunneling is preferred.

## Credits
The packer build is strongly based on https://github.com/boxcutter/centos.

## Contributing

### Update Puppet Modules

Update puppet modules from the `Puppetfile`:
```shell
$ librarian-puppet install --path=environments/dev/modules --destructive --strip-dot-git
```

If the `zanloy-vim` module is updated, the URL to vim-pathogen needs to be changed to a github.com URL to make it past some filtering proxies. Change `https://tpo.pe/pathogen.vim` to `https://raw.githubusercontent.com/tpope/vim-pathogen/v2.4/autoload/pathogen.vim` in the file `environments/dev/modules/vim/manifests/pathogen.pp`.

If the `paulosuzart-sdkman` module is updated, the `su` commands in the file `environments/dev/modules/sdkman/manifests/package.pp` need to be fixed to have a space after the ` - ` to enable a login shell.

### Packer Builds

Packer builds are available for the following providers:

* VirtualBox
* VMware
* Parallels
* AWS
* qemu

The VMs are large, 10-12GB uncompressed. You'll likely need to build them individually.

* packer build -only=virtualbox-iso -var-file=centos7.json centos.json
* packer build -only=vmware-iso -var-file=centos7.json centos.json
* packer build -only=parallels-iso -var-file=centos7.json centos.json
* packer build -only=amazon-ebs -var-file=centos7.json centos.json
* packer build -only=qemu -var-file=centos7.json centos.json

There are environment variables needed for building. If you aren't using a specific build, the variable is required, but a dummy value will do.

* `AWS_ACCESS_KEY` - Access key for AWS EC2 allowing read/write access (not admin) to EC2
* `AWS_SECRET_KEY` - Secret key for AWS
* `VAGRANT_CLOUD_TOKEN` - vagrantcloud.com token for publishing Vagrant boxes

