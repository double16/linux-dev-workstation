# Contributing

Fork this repo, create a branch, and submit a PR. CI is done using CircleCI by using a Docker container to build the Vagrant box. Build your fork to verify your changes pass. See the commands in `.circleci/config.yml` for how it's built.

## Update Puppet Modules

If you want to update the Puppet modules from the Forge, use the following procedure. This is not always needed, but keeping up to date is generally a good idea. The modules are installed from the forge and checked into this repository. There have been problems pulling from the Forge for every build.

Review `Puppetfile` for appropriate versions, then update the modules from the `Puppetfile`:
```shell
$ librarian-puppet install --path=environments/dev/modules --strip-dot-git
```

### Puppet Module Patches

Apply the `puppet_modules.patch` file, which performs the following:

* If the `zanloy-vim` module is updated, the URL to vim-pathogen needs to be changed to a github.com URL to make it past some filtering proxies. Change `https://tpo.pe/pathogen.vim` to `https://raw.githubusercontent.com/tpope/vim-pathogen/v2.4/autoload/pathogen.vim` in the file `environments/dev/modules/vim/manifests/pathogen.pp`.

* If the `paulosuzart-sdkman` module is updated, the `su` commands in the file `environments/dev/modules/sdkman/manifests/package.pp` need to be fixed to have a space after the ` - ` to enable a login shell.

* If the `virtualbox` module is updated, the `environments/dev/modules/virtualbox/manifests/kernel.pp` file needs to specify `environment => 'KERN_VER=``uname -r``',` instead of `KERN_DIR`.

```shell
$ patch -p1 < puppet_modules.patch
```

## Update Packages

Most versions of packages are kept in `environments/dev/hieradata/common.yaml`. The `script/package-update.rb` script will update most of them by querying the Internet. Run the script and do `git diff environments/dev/hieradata/common.yaml` to see the changes. The intent is that the box can be built or updated directly after running the script.

## Packer Builds

Packer builds are available for the following providers:

* VirtualBox
* VMware
* Hyper-V
* Parallels
* AWS
* qemu
* Azure (VHD only, Vagrant box is not supported)

The VMs are large, 10-12GB uncompressed. You'll likely need to build them individually.

* packer build -only=virtualbox-iso -var-file custom-vars.json -var version=YYYYMM.N -var no_release=false packer.json
* packer build -only=vmware-iso     -var-file custom-vars.json -var version=YYYYMM.N -var no_release=false packer.json
* packer-build-hyperv.ps1           (Hyper-V needs setup external to packer)
* packer build -only=parallels-iso  -var-file custom-vars.json -var version=YYYYMM.N -var no_release=false packer.json
* packer build -only=amazon-ebs     -var-file custom-vars.json -var version=YYYYMM.N -var no_release=false packer.json
* packer build -only=qemu           -var-file custom-vars.json -var version=YYYYMM.N -var no_release=false packer.json
* packer build -only=azure-arm      -var-file custom-vars.json -var version=YYYYMM.N -var no_release=false packer.json
* packer build -only=docker         -var-file custom-vars.json -var version=YYYYMM.N -var no_release=false packer.json

There are environment variables needed for building. If you aren't using a specific build, the variable is required, but a dummy value will do.

* `VAGRANT_CLOUD_TOKEN` - vagrantcloud.com token for publishing Vagrant boxes
* `AWS_ACCESS_KEY` - Access key for AWS EC2 allowing read/write access (not admin) to EC2
* `AWS_SECRET_KEY` - Secret key for AWS
* `AZURE_SUBSCRIPTION_ID` - Azure subscription
* `AZURE_TENANT_ID`- - Azure tenant
* `AZURE_CLIENT_ID` - Client ID for Azure
* `AZURE_CLIENT_SECRET` - Secret for Azure

## Building in Azure

If you'd like to use a VM in the cloud to build the boxes, Azure supports nested virtualization. The `builder` directory has a Packer `builder.json` file to build the VM with Packer, VirtualBox or QEMU/libvirt.

### Configure your Azure Account

Azure needs several configurations before you can run the Packer build. Run the `azure-setup.sh` script in this directory. The output is suitable for a Packer variables file. We'll assume you've created a `vars.json` with the output.

### Run Packer

```shell
$ packer build -var-file=vars.json builder.json
```

### Create the VM

Using Vagrant to use the builder VM is recommended. Otherwise, you'll need to follow the instructions provided in this [Packer GitHub issue](https://github.com/Azure/packer-azure/issues/201) to create a VM based on the image.
