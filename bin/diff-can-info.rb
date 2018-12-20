#!/usr/bin/env ruby
# frozen_string_literal: true

require 'pathname'
require 'fileutils'

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

def host_node_dirs(env, host)
  @host_node_dirs ||= {}
  @host_node_dirs[env] ||= {}
  @host_node_dirs[env][host] ||= begin
    nodes_txt = File.read(orig_host_dir(env, host) + 'store/nodes.txt').gsub(/^#[^\n]+\n/, '') # filter comments
    nodes_txt.scan(%r{repository/.+}).sort.map { |d| d.sub(%r{^repository/}, '') }
  end
end

def env_node_dirs(env)
  @env_node_dirs ||= {}
  @env_node_dirs[env] ||= begin
    node_dirs = hosts_for(env).map { |h| host_node_dirs(env, h) }.uniq
    if node_dirs.size > 1
      mismatch = hosts_for(env).map { |h| "#{h} -> #{host_node_dirs(env, h)}" }
      raise "Unexpected mismatch: #{mismatch}"
    end
    node_dirs[0]
  end
end

def can_info_txt(env, node, host)
  node_dir = orig_host_dir(env, host) + 'repository' + node
  (node_dir + 'can-info.txt').relative_path_from(Pathname.pwd)
end

############################################################
# Main program

diffs = []

envs.each do |env|
  env_node_dirs(env).each do |node|
    hosts_for_env = hosts_for(env)
    can_info_by_host = hosts_for_env.map { |host| [host, can_info_txt(env, node, host)] }.to_h
    next unless hosts_for_env.size > 1

    host_0 = hosts_for_env[0]
    can_info_0 = can_info_by_host[host_0]
    hosts_for_env.drop(1).each do |h|
      can_info_h = can_info_by_host[h]
      diff = `diff -u #{can_info_0} #{can_info_h}`
      unless diff.empty?
        puts "\ncan-info.txt mismatch for #{env}:\n\n#{diff}"
        diffs << diff
      end
    end
  end
end

exit(1) unless diffs.empty?
