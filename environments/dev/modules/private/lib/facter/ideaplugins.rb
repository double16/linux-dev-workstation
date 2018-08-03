require 'rexml/document'

Facter.add(:ideaplugins) do
  setcode do
    results = Hash.new

    process_plugin_xml = lambda { |content|
        doc = REXML::Document.new(content)
        doc.elements.each('idea-plugin') do |plugin|
            id = (plugin.elements['id'] || plugin.elements['name']).text
            version = plugin.elements['version'].text
            results[id] = { 'version' => version }
        end
    }

    `find /home/vagrant/.IntelliJIdea*/config/plugins -name '*.jar' -print0 | xargs -0 -L 1 -I{} sh -c "if unzip -v '{}' | grep -qF 'META-INF/plugin.xml'; then echo {}; fi"`.split(/\n/).each do |file|
        process_plugin_xml.call(`unzip -p '#{file}' META-INF/plugin.xml`)
    end

    `find /home/vagrant/.IntelliJIdea*/config/plugins -path '*/META-INF/plugin.xml' -print`.split(/\n/).each do |file|
        process_plugin_xml.call(File.read(file))
    end
  
    results
  end
end
