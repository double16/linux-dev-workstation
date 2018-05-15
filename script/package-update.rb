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
`mkdir -p .vagrant/machines/default/cache`

def sha256(file)
    File.open(file, 'r') do |file|
        sha = Digest::SHA256.new
        while content = file.read(65535)
            sha.update content
        end
        sha.to_s
    end
end

def latest_github_tag(owner, repo, version_match = /^v[0-9.]+$/)
    tags = JSON.parse(Net::HTTP.get(URI("https://api.github.com/repos/#{owner}/#{repo}/tags")))
    tags.collect { |e| e['name'] }
        .select { |e| e.match(version_match) }
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

#
# Update the package_info by downloading from download_url into local download_file.
# package_info is expected to be a map with 'version' and 'checksum' keys. 'checksum' will be a
# sha256 sum.
# @return true if package_info is updated, false if package_info is unchanged
#
def update_single_archive(version, download_url, download_file, package_info)
    system "curl -L -C - -o #{download_file} #{download_url}"
    if File.size(download_file) < 4096
        STDERR.puts "Error downloading #{download_url}, size is only #{File.size(download_file)} bytes"
        File.delete(download_file)
        false
    elsif $?.exitstatus == 0 or $?.exitstatus == 33 # we have the entire file, the byte range request failed
        package_info['checksum'] = sha256(download_file)
        package_info['version'] = version
        true
    else
        STDERR.puts "Error #{$?} downloading #{download_url}"
        false
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
            update_single_archive(latest, download_url, download_file, yaml['hashistack'][tool])
        end
    end
end

def pdk(yaml)
    resp = Net::HTTP.get_response(URI("https://pm.puppetlabs.com/cgi-bin/pdk_download.cgi?dist=el&rel=7&arch=x86_64&ver=latest"))
    if resp.is_a?(Net::HTTPFound)
        location = resp.header['location']
        latest = location.match(/pdk\/([0-9a-z.]+)\//)[1]
        if latest != yaml['pdk']['version']
            puts "Found newer version PDK #{latest}"
            download_url = "https://pm.puppetlabs.com/cgi-bin/pdk_download.cgi?dist=el&rel=7&arch=x86_64&ver=#{latest}"
            download_file = ".vagrant/machines/default/cache/pdk-#{latest}-1.el7.x86_64.rpm"
            update_single_archive(latest, download_url, download_file, yaml['pdk'])
        end
    else
        STDERR.puts "Error getting checking for newer PDK version: #{resp.to_s}"
    end
end

def slack(yaml)
    latest = yaml['slack']['version']
    unless yaml['slack'].has_key?('checksum')
        puts "Found newer version Slack #{latest}"
        download_url = "https://downloads.slack-edge.com/linux_releases/slack-#{latest}.fc21.x86_64.rpm"
        download_file = ".vagrant/machines/default/cache/slack-#{latest}.fc21.x86_64.rpm"
        update_single_archive(latest, download_url, download_file, yaml['slack'])
    end
end

def docker(yaml)
    latest = latest_github_tag('docker', 'docker-ce', /^v[0-9.]+-ce$/)
    if latest
        yaml['docker']['version'] = latest.sub('-ce', '')
    end
end

def git(yaml)
    latest = latest_github_tag('git', 'git')
    if latest
        yaml['git']['version'] = latest
    end
end

def rstudio(yaml)
    latest = latest_github_tag('rstudio', 'rstudio')
    if latest != yaml['rstudio']['version'] or !yaml['rstudio'].has_key?('checksum')
        puts "Found newer version rstudio #{latest}"
        download_url = "https://download1.rstudio.org/rstudio-#{latest}-x86_64.rpm"
        download_file = ".vagrant/machines/default/cache/rstudio-#{latest}-x86_64.rpm"
        update_single_archive(latest, download_url, download_file, yaml['rstudio'])
    end
end

def containerdiff(yaml)
    latest = latest_github_tag('GoogleContainerTools', 'container-diff')
    if latest != yaml['container-diff']['version'] or !yaml['container-diff'].has_key?('checksum')
        puts "Found newer version container-diff #{latest}"
        download_url = "https://storage.googleapis.com/container-diff/v#{latest}/container-diff-linux-amd64"
        download_file = ".vagrant/machines/default/cache/container-diff-#{latest}"
        update_single_archive(latest, download_url, download_file, yaml['container-diff'])
    end
end

def kitematic(yaml)
    latest = latest_github_tag('docker', 'kitematic')
    if latest != yaml['kitematic']['version'] or !yaml['kitematic'].has_key?('checksum')
        puts "Found newer version kitematic #{latest}"
        download_url = "https://github.com/docker/kitematic/releases/download/v#{latest}/Kitematic-#{latest}-Ubuntu.zip"
        download_file = ".vagrant/machines/default/cache/Kitematic-#{latest}.zip"
        update_single_archive(latest, download_url, download_file, yaml['kitematic'])
    end
end

def nodejs(yaml)
    tags = JSON.parse(Net::HTTP.get(URI("https://api.github.com/repos/nodejs/node/tags")))
    versions = tags.collect { |e| e['name'] }
        .select { |e| e.match(/^v[0-9.]+$/) }
        .collect { |e| e[1..-1] }
    yaml['node']['versions'].each do |info|
        current_spec = Gem::Version.new(info['version']).approximate_recommendation()
        latest = versions.select { |e| Gem::Version.new(e).approximate_recommendation() == current_spec }
            .sort { |a,b| Gem::Version.new(a) <=> Gem::Version.new(b) }
            .reverse
            .first
        info['version'] = latest if latest
    end
end

yaml = File.open(YAML_FILE) { |file| YAML.load(file) }

idea(yaml)
hashistack(yaml)
pdk(yaml)
slack(yaml)
docker(yaml)
rstudio(yaml)
containerdiff(yaml)
kitematic(yaml)
git(yaml)
nodejs(yaml)
# sdkman(yaml) # sdkman has an API for itself to check for later versions, could use that
# emacs(yaml) # source on ftp.gnu.org, no perceivable way to check for updates and it doesn't happen often
# ruby(yaml) # use local rbenv? different sources, such as ruby and jruby

File.open(YAML_FILE, 'w') { |file| file.write(yaml.to_yaml) }
