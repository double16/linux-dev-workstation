#!/usr/bin/env ruby
#
# Updates common.yaml versions with the latest from the 'net
#
require 'yaml'
require 'nokogiri'
require 'net/http'
require 'cgi'

YAML_FILE = 'environments/dev/hieradata/common.yaml'
TMPDIR = "tmp"
Dir.mkdir(TMPDIR, 0775) unless Dir.exist?(TMPDIR)

#
# https://plugins.jetbrains.com/plugins/list?build=IU-181.4668.68
# https://plugins.jetbrains.com/pluginManager?action=download&id=com.handyedit.AntDebugger&build=IC-107.322
#  responds with 302, Location: https://plugins.jetbrains.com/files/9746/43008/com.jetbrains.ideolog-181.0.7.0.jar?updateId=43008&pluginId=9746&uuid&code=IU&build=181.4668.68
#
def idea(yaml)
    idea_build = "IU-#{yaml['idea']['build']}"
    idea_plugins_file = File.join(TMPDIR, 'idea-plugins.xml')
    if !File.exist?(idea_plugins_file) or Time.now - File.mtime(idea_plugins_file) > (12*3600) # seconds
        File.open(idea_plugins_file, 'w') { |file|
            file.write(Net::HTTP.get(URI("https://plugins.jetbrains.com/plugins/list?build=#{idea_build}")))
        }
    end

    doc = File.open(idea_plugins_file) { |file| Nokogiri::XML(file) }
    available_plugins = doc.xpath('//idea-plugin')
    yaml['idea']['plugins'].each do |existing_plugin|
        available_plugin = available_plugins.find { |p| p.at_xpath("id[text()=\"#{existing_plugin['name']}\"]") }
        if available_plugin
            available_version = available_plugin.xpath("version").first.text
            if available_version and available_version.to_s != existing_plugin['version'].to_s
                STDERR.puts "Getting new version of #{existing_plugin['name']}, #{available_version}"
                resp = Net::HTTP.get_response(URI("https://plugins.jetbrains.com/pluginManager?action=download&id=#{existing_plugin['name']}&build=#{idea_build}"))
                if resp.is_a?(Net::HTTPFound)
                    location = URI(resp.header['location'])
                    params = CGI.parse(location.query)
                    new_type = location.path.split('.').last
                    new_updateid = params['updateId'].first
                    if new_type and new_updateid
                        existing_plugin['type'] = new_type
                        existing_plugin['updateid'] = new_updateid
                        existing_plugin['version'] = available_version
                    end
                else
                    STDERR.puts "Error getting new version: #{resp.to_s}"
                end
            end
        else
            STDERR.puts "#{existing_plugin['name']} NOT-FOUND"
        end
    end
end

yaml = File.open(YAML_FILE) { |file| YAML.load(file) }

idea(yaml)

File.open(YAML_FILE, 'w') { |file| file.write(yaml.to_yaml) }
