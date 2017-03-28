Linux Java/DevOps Workstation
=============================

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
$ librarian-puppet install --path=environments/dev/modules --destructive
```


