# Linux Java/DevOps Workstation

This Vagrant image contains a developer workspace with the following software:

* Fedora 32
* Java 8-14
* [IntelliJ IDEA Ultimate, Community Edition and sundry plugins](https://www.jetbrains.com/idea/)
* [Visual Studio Code](https://code.visualstudio.com)
* vim 8, gvim, sundry vim plugins
* emacs with [spacemacs](https://github.com/syl20bnr/spacemacs)
* ZSH + [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)
* [Editor Config](http://editorconfig.org) support in most IDEs and editors
* git
* svn
* [Docker](https://www.docker.com), Docker Compose, [Dockstation](https://dockstation.io)
* Python 3 and 2
* asciidoc
* nodenv (NodeJS environments)
* [rbenv](https://github.com/rbenv/rbenv) (Ruby Environments)
* [Maven](https://maven.apache.org)
* [Ansible](https://www.ansible.com)
* Puppet, Puppet Development Kit
* [Slack](https://slack.com)
* Xfce Desktop
* [Firefox](https://www.mozilla.org/en-US/firefox/)
* Google Chrome
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
* Kubernetes: [k3s](https://k3s.io), [kubectl](https://github.com/kubernetes/kubectl/blob/master/README.md), [helm](https://helm.sh)

It also features configuration options:

* Solarized Theme configuration across many applications
* Configuring HTTP proxies from standard environment variables (HTTP_PROXY, ...) or configuration described in [VAGRANTUP.md](VAGRANTUP.md).
* Import of SSH keys
* Import of CA certifications
* Checkout of source code repositories when provisioning the Vagrant box

## Configure

See [VAGRANTUP.md](VAGRANTUP.md) for configuration details. This file is also included in the box built by Packer and output after the `vagrant up`.

## Installation

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

## Hyper-V

There is some setup required before using Hyper-V. Run the following commands in PowerShell as an Administrator:

```powershell
PS > Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
PS > .\create-natswitch.ps1     # ignore errors, these are from detecting existing networking
```

## SSL Certificates

If you need custom SSL certificates to be trusted, the following will download and add a sites certificate chain to the trust store. This is usually only needed when using a corporate proxy that intercepts SSL traffic.

```shell
$ mkdir certs.d
$ openssl s_client -servername www.google.com -connect www.google.com:443 2>/dev/null </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > certs.d/www.google.com.pem
$ vagrant provision
```

## Credits

The packer build is strongly based on https://github.com/boxcutter/fedora.
