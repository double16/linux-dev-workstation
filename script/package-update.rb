#!/usr/bin/env ruby
#
# Updates common.yaml versions with the latest from the 'net
#
require 'yaml'
require 'nokogiri'
require 'net/http'
require 'cgi'
require 'digest'
require 'json'

YAML_FILE = 'environments/dev/hieradata/common.yaml'
TMPDIR = "tmp"
Dir.mkdir(TMPDIR, 0775) unless Dir.exist?(TMPDIR)

def sha256(file)
    File.open(file, 'r') do |file|
        sha = Digest::SHA256.new
        while content = file.read(65535)
            sha.update content
        end
        sha.to_s
    end
end

def latest_github_tag(owner, repo)
    tags = JSON.parse(Net::HTTP.get(URI("https://api.github.com/repos/#{owner}/#{repo}/tags")))
    tags.collect { |e| e['name'] }
        .select { |e| e.match?(/^v[0-9.]+$/) }
        .collect { |e| e[1..-1] }
        .sort { |a,b| Gem::Version.new(a) <=> Gem::Version.new(b) }
        .reverse
        .first
end

#
# https://plugins.jetbrains.com/plugins/list?build=IU-181.4668.68
# https://plugins.jetbrains.com/pluginManager?action=download&id=com.handyedit.AntDebugger&build=IC-107.322
#  responds with 302, Location: https://plugins.jetbrains.com/files/9746/43008/com.jetbrains.ideolog-181.0.7.0.jar?updateId=43008&pluginId=9746&uuid&code=IU&build=181.4668.68
#
def idea(yaml)
    idea_channel = yaml['idea']['channel'] || 'IDEA_Release'
    idea_version = "#{yaml['idea']['version']}"
    idea_build = "IU-#{yaml['idea']['build']}"
    idea_plugins_file = File.join(TMPDIR, 'idea-plugins.xml')
    idea_updates_file = File.join(TMPDIR, 'idea-updates.xml')

    # IDEA version
    if !File.exist?(idea_updates_file) or Time.now - File.mtime(idea_updates_file) > (12*3600) # seconds
        File.open(idea_updates_file, 'w') { |file|
            file.write(Net::HTTP.get(URI("https://www.jetbrains.com/updates/updates.xml")))
        }
    end
    updates_doc = File.open(idea_updates_file) { |file| Nokogiri::XML(file) }
    latest_build = updates_doc.xpath("//channel[@id=\"#{idea_channel}\"]//build")[0]['fullNumber'].to_s
    if yaml['idea']['build'] != latest_build
        latest_version = updates_doc.xpath("//channel[@id=\"#{idea_channel}\"]//build")[0]['version'].to_s.sub(/ .*/, '')
        puts "Updating IDEA to #{latest_version} #{latest_build} ..."
        download_url = "https://download-cf.jetbrains.com/idea/ideaIU-#{latest_version}.tar.gz"
        download_file = ".vagrant/machines/default/cache/idea-#{latest_version}.tar.gz"
        system "curl -L -C - -o #{download_file} #{download_url}"
        if $?.exitstatus == 0 or $?.exitstatus == 33 # we have the entire file, the byte range request failed
            yaml['idea']['checksum'] = sha256(download_file)
            idea_version = yaml['idea']['version'] = latest_version
            yaml['idea']['build'] = latest_build
            idea_build = "IU-#{yaml['idea']['build']}"
            File.delete(idea_plugins_file)
            puts "IDEA updated to  #{latest_version} #{latest_build}, SHA256 #{yaml['idea']['checksum']}"
        else
            STDERR.puts "Error #{$?} downloading #{download_url}"
        end
    end

    # plugins
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
                puts "Getting new version of #{existing_plugin['name']}, #{available_version}"
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

def hashistack(yaml)
    yaml['vagrant']['version'] = latest_github_tag('hashicorp', 'vagrant')
    yaml['hashistack'].each do |tool, info|
        latest = latest_github_tag('hashicorp', tool)
        if (latest != info['version'] or !info.has_key?('checksum'))
            puts "Found newer version #{tool} #{latest}"
            download_url = "https://releases.hashicorp.com/#{tool}/#{latest}/#{tool}_#{latest}_linux_amd64.zip"
            download_file = ".vagrant/machines/default/cache/#{tool}_#{latest}_linux_amd64.zip"
            system "curl -L -C - -o #{download_file} #{download_url}"
            if $?.exitstatus == 0 or $?.exitstatus == 33 # we have the entire file, the byte range request failed
                yaml['hashistack'][tool]['checksum'] = sha256(download_file)
                yaml['hashistack'][tool]['version'] = latest
            else
                STDERR.puts "Error #{$?} downloading #{download_url}"
            end
        end
    end
end

yaml = File.open(YAML_FILE) { |file| YAML.load(file) }

#idea(yaml)
hashistack(yaml)

File.open(YAML_FILE, 'w') { |file| file.write(yaml.to_yaml) }
