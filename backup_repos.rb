#!/usr/bin/env ruby

# frozen_string_literal: true

require 'nitlink'
require 'rest-client'
require 'fileutils'
require 'json'
require 'English'
require 'shellwords'

REPOS_FOLDER = './repos'
TOKEN_FILE = File.join(ENV['HOME'], '.gltools.token')

def backup_repo name, url
  puts "Backing up repo '#{name}'..."

  # Find a subfolder name that does not already exist.
  subfolder = name
  if Dir.exist?(subfolder)
    i = 1
    i += 1 while Dir.exist?("#{subfolder}-#{i}")
    subfolder = "#{subfolder}-#{i}"
  end

  got_warning = false

  cmd = ['git', 'clone', url, subfolder].shelljoin
  unless system(cmd)
    warn "git clone failed for url #{url}, subfolder #{subfolder}: exit code #{$CHILD_STATUS}"
    return
  end

  cmd = ['git', '-C', subfolder, 'bundle', 'create', "../#{subfolder}.bundle", '--all'].shelljoin
  unless system(cmd)
    warn "git bundle failed for subfolder #{subfolder}: exit code #{$CHILD_STATUS}"
    got_warning = true
  end

  cmd = ['git', '-C', subfolder, 'archive', '--format', 'zip', '--prefix', "#{subfolder}/", '-9', '-o', "../#{subfolder}.zip", 'HEAD'].shelljoin
  unless system(cmd)
    warn "git archive failed for subfolder #{subfolder}: exit code #{$CHILD_STATUS}"
    got_warning = true
  end

  FileUtils.rm_rf(subfolder) unless got_warning
end

def backup_repos
  token = File.open(TOKEN_FILE, &:readline).strip

  Dir.mkdir(REPOS_FOLDER) unless Dir.exist?(REPOS_FOLDER)
  Dir.chdir(REPOS_FOLDER)

  res = RestClient.get('https://gitlab.com/api/v4/user',
                       params: { private_token: token })
  json = JSON.parse(res.body)
  username = json['username']

  res = RestClient.get("https://gitlab.com/api/v4/users/#{username}/projects",
                       params: { private_token: token, owned: true, simple: true })
  link_parser = Nitlink::Parser.new

  loop {
    json = JSON.parse(res.body)
    links = link_parser.parse(res)

    json.each { |repo|
      name = repo['name']
      url = repo['ssh_url_to_repo']
      backup_repo(name, url)
    }

    next_link = links.by_rel('next')
    break unless next_link

    res = RestClient.get(next_link.target.to_s)
  }
end

backup_repos

__END__
