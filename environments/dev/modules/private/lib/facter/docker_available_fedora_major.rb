Facter.add(:docker_available_fedora_major) do
  setcode do
    major = Facter.value(:os)['release']['major'].to_i
    return nil if major.nil?
    found = nil
    [major, major-1, major-2].each do |v|
      if found.nil?
        resp = Net::HTTP.get_response(URI("https://download.docker.com/linux/fedora/#{v}/x86_64/stable/repodata/repomd.xml"))
        if resp.is_a?(Net::HTTPOK) or resp.is_a?(Net::HTTPFound) or resp.is_a?(Net::HTTPSeeOther)
          found = v
        end
      end
    end
    (found == major) ? nil : found
  end
end
