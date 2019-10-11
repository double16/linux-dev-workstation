# Install software necessary for running a Vagrant development environment

Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco install git
choco install vagrant
choco install ruby
choco install vnc-viewer
choco install docker-desktop
choco install virtualbox
choco install packer
choco install vscode

