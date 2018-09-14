Facter.add(:vagrant_cache_mounted) do
  setcode do
    system('/usr/bin/mountpoint -q /tmp/vagrant-cache')
  end
end
