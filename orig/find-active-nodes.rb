#!/usr/bin/env ruby

require 'pathname'
require 'fileutils'

env_to_hosts = {
  # skip dev since we're shutting it down
  # dev: ['uc3-mrtstore2-dev'],
  stg: ['uc3-mrtstore-stg', 'uc3-mrtstore2-stg'],
  prd: ['uc3-mrtstore1-prd', 'uc3-mrtstore2-prd']
}

orig_path = Pathname.new(__dir__)
project_root_path = orig_path.parent

env_to_hosts.each do |env, hosts|
  puts "Environment: #{env}"
  env_str = env.to_s
  fqhosts = hosts.map { |h| "#{h}.cdlib.org" }
  orig_env_path = orig_path + env_str
  new_env_path = project_root_path + env_str
  fqhosts.each do |h|
    puts "Host: #{h}"
    host_path = orig_env_path + h
    orig_store_path = host_path + 'store'
    orig_nodes_txt = File.read(orig_store_path + 'nodes.txt').gsub(/^#[^\n]+\n/,'') # filter comments
    active_node_dirs = orig_nodes_txt.scan(%r{repository/.+}).sort

    active_node_dirs.each do |d|
      orig_node_dir_path = host_path + d
      new_node_dir_path = new_env_path + d
      if File.exist?(new_node_dir_path)
        puts "#{new_node_dir_path} exists"
      else
        puts "Creating #{new_node_dir_path}"
        FileUtils.mkdir_p(new_node_dir_path)
      end
      orig_can_info_path = orig_node_dir_path + 'can-info.txt'
      new_can_info_path = new_node_dir_path + "can-info-#{h}.txt"
      puts "Copying #{orig_can_info_path} to #{new_can_info_path}"
      FileUtils.copy(orig_can_info_path, new_can_info_path)
    end

    new_store_path = new_env_path + 'store'
    FileUtils.mkdir_p(new_store_path)
    new_nodes_txt = new_store_path + "nodes-#{h}.txt"
    File.open(new_nodes_txt, 'w') do |f|
      puts "Writing #{new_nodes_txt}"
      f.puts(active_node_dirs.join"\n")
    end
    orig_store_info_path = orig_store_path + 'store-info.txt'
    new_store_info_path = new_store_path + "store-info-#{h}.txt"
    puts "Copying #{orig_store_info_path} to #{new_store_info_path}"
    FileUtils.copy(orig_store_info_path, new_store_info_path)
  end
end