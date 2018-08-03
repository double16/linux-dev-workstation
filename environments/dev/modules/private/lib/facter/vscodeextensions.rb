Facter.add(:vscodeextensions) do
  setcode do
    results = []

    if File.exists?('/usr/bin/code')
        results += `su vagrant -c "/usr/bin/code --list-extensions"`.split(/\n/)
    end

    results
  end
end
