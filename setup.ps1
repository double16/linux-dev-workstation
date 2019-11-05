# Install software necessary for running a Vagrant development environment

$ChocoInstalled = Test-Path -Path "$env:ProgramData\Chocolatey"
if ($ChocoInstalled -eq $false) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

choco install -y git
choco install -y vagrant
choco install -y ruby
choco install -y vnc-viewer
choco install -y docker-desktop
choco install -y virtualbox
choco install -y packer
choco install -y vscode vscode-gitignore vscode-vsliveshare vscode-puppet vscode-ruby vscode-yaml vscode-gitlens vscode-markdownlint vscode-docker vscode-powershell vscode-settingssync vscode-icons
