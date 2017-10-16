Linux Java/DevOps Workstation
=============================

This Vagrant image contains a developer workspace with the following software:

* CentOS 7
* Java 8
* Java 9
* IntelliJ IDEA Ultimate
* NetBeans
* vim 8, gvim, various vim plugins
* git
* svn
* Docker, Docker Compose, Kitematic
* Python 2
* asciidoc
* nodenv (NodeJS environments)
* Maven
* Ansible
* Puppet
* rbenv (Ruby Environments)
* HipChat
* Xfce Desktop
* Firefox
* Chrome
* VirtualBox
* Vagrant
* sdkman
* Groovy
* Gradle
* Grails

Configure
---------
The `config.yaml` file has several machine size configurations. The default is medium, you can change that by changing the `use` entry in `config.yaml`.

Installation
------------

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

Update Puppet Modules
---------------------

Update puppet modules from the `Puppetfile`:
```shell
$ librarian-puppet install --path=environments/dev/modules --destructive --strip-dot-git
```

If the `zanloy-vim` module is updated, the URL to vim-pathogen needs to be changed to a github.com URL to make it past some filtering proxies. Change `https://tpo.pe/pathogen.vim` to `https://raw.githubusercontent.com/tpope/vim-pathogen/v2.4/autoload/pathogen.vim` in the file `environments/dev/modules/vim/manifests/pathogen.pp`.

Credits
-------
The packer build is strongly based on https://github.com/boxcutter/centos.

