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
* Puppet, Puppet Development Kit
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
* [Packer](http://packer.io)
* [Consul](http://consul.io)
* [Vault](http://vaultproject.io)

It also features configuration options:

* Configuring HTTP proxies from standard environment variables (HTTP_PROXY, ...) or configuration described in [VAGRANTUP.md](VAGRANTUP.md).
* Import of SSH keys
* Import of CA certifications
* Checkout of source code repositories when bringing the Vagrant box up

## Configure
See [VAGRANTUP.md](VAGRANTUP.md) for configuration details. This file is also included in the box built by Packer and output after the `vagrant up`.

## Installation

It is recommended to enable caching of OS packages using the `vagrant-cachier` plugin.
```shell
$ vagrant plugin install vagrant-cachier
```

If you are using VirtualBox, the `vagrant-vbguest` plugin is recommended to maintain the guest additions at the same level as your VirtualBox install.
```shell
$ vagrant plugin install vagrant-vbguest
```

You can choose either to build the box by checking out this repo or creating a Vagrantfile based on the box published at vagrantcloud.com. If you choose to checkout this repo you will be able to update it as the repo changes.

Create a new Vagrantfile based on this box:
```shell
$ mkdir my-dev-box
$ cd my-dev-box
$ vagrant init double16/linux-dev-workstation
```

Finally, vagrant up:
```shell
$ vagrant up
```

## Updates

If you have cloned this repo or forked it then keeping this box up to date is easy. There is no need to re-create the box when there is a new download on vagrantcloud.com. The box uses Puppet to do provisioning both with Packer and Vagrant. The following commands will give you the latest:

```shell
$ git pull
$ vagrant provision
```

Make sure to read [VAGRANTUP.md](VAGRANTUP.md) !

## Credits
The packer build is strongly based on https://github.com/boxcutter/centos.

