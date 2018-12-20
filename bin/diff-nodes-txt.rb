#!/usr/bin/env ruby

require 'pathname'
require 'fileutils'
require 'tempfile'

############################################################
# Accessors

def env_to_hosts
  @env_to_hosts ||= {
    dev: ['uc3-mrtstore2-dev'],
    stg: ['uc3-mrtstore-stg', 'uc3-mrtstore2-stg'],
    prd: ['uc3-mrtstore1-prd', 'uc3-mrtstore2-prd']
  }
end

def envs
  @envs ||= env_to_hosts.keys
end

def hosts
  @hosts ||= env_to_hosts.values.flatten
end

def project_dir
  @project_dir ||= Pathname.new(__dir__).parent
end

def orig_dir
  @orig_dir ||= project_dir + 'orig'
end

def orig_host_dir(env, host)
  @orig_host_dirs ||= {}
  @orig_host_dirs[env] ||= {}
  @orig_host_dirs[env][host] ||= begin
    orig_dir + env.to_s + fq(host)
  end
end

############################################################
# Utility methods

def fq(host)
  "#{host}.cdlib.org"
end

def hosts_for(env)
  env_to_hosts[env]
end

def env_for(host)
  env_to_hosts.each do |env, hosts|
    return env if hosts.include?(host)
  end
  nil
end

def nodes_txt(env, host)
  store_dir = orig_host_dir(env, host) + 'store'
  (store_dir + 'nodes.txt').relative_path_from(Pathname.pwd)
end

def nodes_txt_lines(env, host)
  File.read(nodes_txt(env, host)).gsub(/^#[^\n]+\n/, '').split.sort
end

############################################################
# Main program

diffs = []

envs.each do |env|
  hosts_for_env = hosts_for(env)
  nodes_by_host = hosts_for_env.map { |host| [host, nodes_txt_lines(env, host)] }.to_h
  next unless hosts_for_env.size > 1

  host_0 = hosts_for_env[0]
  nodes_0 = nodes_by_host[host_0]
  hosts_for_env.drop(1).each do |h|
    nodes_h = nodes_by_host[h]
    next if nodes_0 == nodes_h

    left = (nodes_0 - nodes_h).join("\n")
    right = (nodes_h - nodes_0).join("\n")

    diff = ''
    unless left.empty?
      diff << "\n"
      diff << "in nodes.txt for #{host_0}, not in nodes.txt for #{h}:\n\n"
      diff << left
      diff << "\n"
    end
    unless right.empty?
      diff << "\n"
      diff << "in nodes.txt for #{h}, not in nodes.txt for #{host_0}:\n\n"
      diff << right
      diff << "\n"
    end
    # diff = "#{host_0}:\n#{left.join("\n")}>>>\n#{right.join("\n")}"
    puts "\nnodes.txt mismatch for #{env}:\n#{diff}"
    diffs << diff
  end
end

exit(1) unless diffs.empty?
