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

def latest_github_tag(owner, repo, version_match = /^v[0-9.]+$/, filter = lambda { |v| true })
    uri_str = "https://api.github.com/repos/#{owner}/#{repo}/tags"
    tags = JSON.parse(Net::HTTP.get(URI(uri_str)))
    
    if tags.is_a?(Hash) and tags.has_key?('message')
        STDERR.puts "Error contacting #{uri_str}: #{tags['message']}"
        return nil
    end

    tags.collect { |e| e['name'] }
        .select { |e| e.match(version_match) }
        .collect { |e| e[1..-1] }
        .sort { |a,b| Gem::Version.new(a) <=> Gem::Version.new(b) }
        .reverse
        .select { |v| filter.call(v) }
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
            File.delete(idea_plugins_file) if File.exists?(idea_plugins_file)
            puts "IDEA updated to #{latest_version} #{latest_build}, SHA256 #{yaml['idea']['checksum']}"
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
    yaml['vagrant']['version'] = latest_github_tag('hashicorp', 'vagrant') || yaml['vagrant']['version']
    yaml['hashistack'].each do |tool, info|
        latest = latest_github_tag('hashicorp', tool) || info['version']
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
            download_file = ".vagrant/machines/default/cache/pdk-#{latest}-1.el7.x86_64.rpm"
            update_single_archive(latest, location, download_file, yaml['pdk'])
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
    latest = latest_github_tag('docker', 'docker-ce', /^v[0-9.]+-ce$/, lambda { |v|
        docker_uri = URI("https://download.docker.com/linux/static/stable/x86_64/docker-#{v}.tgz")
        resp = Net::HTTP.start(docker_uri.host, docker_uri.port, :use_ssl => true) { |http|
            http.head(docker_uri.path)
        }
        resp.is_a?(Net::HTTPFound) || resp.is_a?(Net::HTTPSuccess)
    })
    if yaml['docker']['pin']
        latest = yaml['docker']['version']
    end
    if latest
        yaml['docker']['version'] = latest.sub('-ce', '')
    end
end

def git(yaml)
    latest = latest_github_tag('git', 'git')
    if yaml['git']['pin']
        latest = yaml['git']['version']
    end
    if latest
        yaml['git']['version'] = latest
    end
end

def vim(yaml)
    latest = latest_github_tag('vim', 'vim')
    if yaml['vim']['pin']
        latest = yaml['vim']['version']
    end
    if latest
        yaml['vim']['version'] = latest
    end
end

def rstudio(yaml)
    # Only version 1.1.* has packages
    latest = latest_github_tag('rstudio', 'rstudio', /^v1[.]1[.][0-9.]+$/)
    return if latest.nil?
    if yaml['rstudio']['pin']
        latest = yaml['rstudio']['version']
    end
    if latest != yaml['rstudio']['version'] or !yaml['rstudio'].has_key?('checksum')
        puts "Found newer version rstudio #{latest}"
        download_url = "https://download1.rstudio.org/rstudio-#{latest}-x86_64.rpm"
        download_file = ".vagrant/machines/default/cache/rstudio-#{latest}-x86_64.rpm"
        update_single_archive(latest, download_url, download_file, yaml['rstudio'])
    end
end

def containerdiff(yaml)
    latest = latest_github_tag('GoogleContainerTools', 'container-diff')
    return if latest.nil?
    if yaml['container-diff']['pin']
        latest = yaml['container-diff']['version']
    end
    if latest != yaml['container-diff']['version'] or !yaml['container-diff'].has_key?('checksum')
        puts "Found newer version container-diff #{latest}"
        download_url = "https://storage.googleapis.com/container-diff/v#{latest}/container-diff-linux-amd64"
        download_file = ".vagrant/machines/default/cache/container-diff-#{latest}"
        update_single_archive(latest, download_url, download_file, yaml['container-diff'])
    end
end

def kustomize(yaml)
    latest = latest_github_tag('kubernetes-sigs', 'kustomize')
    return if latest.nil?
    if yaml['kustomize']['pin']
        latest = yaml['kustomize']['version']
    end
    if latest != yaml['kustomize']['version'] or !yaml['kustomize'].has_key?('checksum')
        puts "Found newer version kustomize #{latest}"
        download_url = "https://github.com/kubernetes-sigs/kustomize/releases/download/v#{latest}/kustomize_#{latest}_linux_amd64"
        download_file = ".vagrant/machines/default/cache/kustomize-#{latest}"
        update_single_archive(latest, download_url, download_file, yaml['kustomize'])
    end
end

def minikube(yaml)
    latest = latest_github_tag('kubernetes', 'minikube')
    return if latest.nil?
    if yaml['minikube']['pin']
        latest = yaml['minikube']['version']
    end
    if latest != yaml['minikube']['version'] or !yaml['minikube'].has_key?('checksum')
        puts "Found newer version minikube #{latest}"
        download_url = "https://storage.googleapis.com/minikube/releases/v#{latest}/minikube-linux-amd64"
        download_file = ".vagrant/machines/default/cache/minikube-#{latest}"
        update_single_archive(latest, download_url, download_file, yaml['minikube'])
    end
end

def helm(yaml)
    latest = latest_github_tag('helm', 'helm')
    return if latest.nil?
    if yaml['helm']['pin']
        latest = yaml['helm']['version']
    end
    if latest != yaml['helm']['version'] or !yaml['helm'].has_key?('checksum')
        puts "Found newer version helm #{latest}"
        download_url = "https://storage.googleapis.com/kubernetes-helm/helm-v#{latest}-linux-amd64.tar.gz"
        download_file = ".vagrant/machines/default/cache/helm-#{latest}.tar.gz"
        update_single_archive(latest, download_url, download_file, yaml['helm'])
    end
end

def dockstation(yaml)
    latest = latest_github_tag('DockStation', 'dockstation')
    return if latest.nil?
    if yaml['dockstation']['pin']
        latest = yaml['dockstation']['version']
    end
    if latest != yaml['dockstation']['version'] or !yaml['dockstation'].has_key?('checksum')
        puts "Found newer version dockstation #{latest}"
        download_url = "https://github.com/DockStation/dockstation/releases/download/v#{latest}/dockstation-#{latest}-x86_64.AppImage"
        download_file = ".vagrant/machines/default/cache/dockstation-#{latest}-x86_64.AppImage"
        update_single_archive(latest, download_url, download_file, yaml['dockstation'])
    end
end

def nodejs(yaml)
    tags = JSON.parse(Net::HTTP.get(URI("https://api.github.com/repos/nodejs/node/tags")))
    return if tags.is_a?(Hash)
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

def sdkman(yaml)
    yaml['sdkman'].each do |tool|
        candidate = tool['package']
        version = tool['version'].to_s
        candidate_file = File.join(TMPDIR, "sdkman-#{candidate}.txt")
        if !File.exist?(candidate_file) or Time.now - File.mtime(candidate_file) > (12*3600) # seconds
            File.open(candidate_file, 'w') { |file|
                file.write(Net::HTTP.get(URI("https://api.sdkman.io/1/candidates/#{candidate}/list?platform=Linux")))
            }
        end
        (x, prefix, suffix) = version.match(/^([0-9.]+)(.*)$/).to_a
        suffix = '' if suffix.nil?
        re = Regexp.new('^'+prefix.split(/[.]/)[0..-2].join('[.]')+"[.][0-9.]+#{suffix}$")
        latest_version = version
        File.open(candidate_file) do |file|
            file.each_line { |line|
                line.split(/\s+/).each { |word|
                    if (re.match(word))
                        v = Gem::Version.new(word)
                        if (v > Gem::Version.new(latest_version))
                            latest_version = word
                        end
                    end
                }
            }
        end
        if (latest_version != version)
            tool['version'] = latest_version
            puts "Found newer version #{candidate} #{latest_version}"
        end
    end
end

def ruby(yaml)
    ruby_build_d = File.join(TMPDIR, "ruby-build")
    if !File.exist?(ruby_build_d)
        `git clone --single-branch https://github.com/rbenv/ruby-build.git #{ruby_build_d}`
    elsif Time.now - File.mtime(ruby_build_d) > (12*3600) # seconds
        `cd #{ruby_build_d} ; git pull`
    end
    yaml['ruby']['versions'].each do |version_info|
        version = version_info['version'].to_s
        (x, prefix, numbers, patch, suffix) = version.match(/^([A-Za-z]+-)?([0-9.]+)(-p[0-9]+)?(.*)$/).to_a
        prefix = '' if prefix.nil?
        suffix = '' if suffix.nil?
        if patch
            re = Regexp.new("^#{prefix}#{numbers}-p[0-9]+#{suffix}$")
        else
            back = -2
            back = -3 if prefix == 'jruby-' and !version.start_with?('jruby-1.')
            re = Regexp.new("^#{prefix}"+numbers.split(/[.]/)[0..back].join('[.]')+"[.][0-9.]+#{suffix}$")
        end
        latest_version = version
        Dir.new("#{ruby_build_d}/share/ruby-build").each do |available|
            if (re.match(available))
                v = Gem::Version.new(available[prefix.length, available.length])
                if (v > Gem::Version.new(latest_version[prefix.length, latest_version.length]))
                    latest_version = available
                end
            end
        end
        if (latest_version != version)
            version_info['version'] = latest_version
            puts "Found newer version ruby #{latest_version}"
        end
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
kustomize(yaml)
minikube(yaml)
helm(yaml)
dockstation(yaml)
git(yaml)
vim(yaml)
nodejs(yaml)
sdkman(yaml)
ruby(yaml)

#IGNORE: emacs(yaml) # source on ftp.gnu.org, no perceivable way to check for updates and it doesn't happen often

File.open(YAML_FILE, 'w') { |file| file.write(yaml.to_yaml) }
