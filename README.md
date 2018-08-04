# Linux Java/DevOps Workstation

This Vagrant image contains a developer workspace with the following software:

* CentOS 7.5
* Java 8, 9, 10
* [IntelliJ IDEA Ultimate + sundry plugins](https://www.jetbrains.com/idea/)
* [Visual Studio Code](https://code.visualstudio.com)
* vim 8, gvim, sundry vim plugins
* emacs with [spacemacs](https://github.com/syl20bnr/spacemacs)
* [Editor Config](http://editorconfig.org) support in most IDEs and editors
* git
* svn
* [Docker](https://www.docker.com), Docker Compose, [Dockstation](https://dockstation.io)
* Python 2
* asciidoc
* nodenv (NodeJS environments)
* [rbenv](https://github.com/rbenv/rbenv) (Ruby Environments)
* [Maven](https://maven.apache.org)
* [Ansible](https://www.ansible.com)
* Puppet, Puppet Development Kit
* [Slack](https://slack.com)
* Xfce Desktop
* [Firefox](https://www.mozilla.org/en-US/firefox/)
* Chrome
* [VirtualBox](https://www.virtualbox.org)
* [Vagrant](https://www.vagrantup.com)
* [R, RStudio](https://www.rstudio.com)
* [sdkman](http://sdkman.io)
* [Groovy](http://groovy-lang.org) via sdkman
* [Gradle](https://gradle.org) via sdkman
* [Grails](https://grails.org) via sdkman
* [Packer](http://packer.io)
* [Consul](http://consul.io)
* [Vault](http://vaultproject.io)
* [Terraform](https://www.terraform.io)
* [iTerm2](https://iterm2.com) shell integration
* [CircleCI](https://circleci.com/docs/2.0/local-jobs/) CLI

It also features configuration options:

* Solarized Theme configuration across many applications
* Configuring HTTP proxies from standard environment variables (HTTP_PROXY, ...) or configuration described in [VAGRANTUP.md](VAGRANTUP.md).
* Import of SSH keys
* Import of CA certifications
* Checkout of source code repositories when provisioning the Vagrant box

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

