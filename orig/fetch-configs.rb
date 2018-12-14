#!/usr/bin/env ruby

require 'pathname'
require 'sshkit'
require 'sshkit/dsl'

include SSHKit::DSL

user = 'dmoles'

env_to_hosts = {
  dev: ['uc3-mrtstore2-dev'],
  stg: ['uc3-mrtstore-stg', 'uc3-mrtstore2-stg'],
  prd: ['uc3-mrtstore1-prd', 'uc3-mrtstore2-prd']
}

env_to_hosts.each do |env, hosts|
  puts "Environment: #{env}"
  fqhosts = hosts.map { |h| SSHKit::Host.new("#{user}@#{h}.cdlib.org") }
  on fqhosts do |h|
    # fetch nodes.txt, store-info.txt
    store_dir = "#{env}/#{h}/store"
    `mkdir -p #{store_dir}`
    within '/dpr2store/mrtHomes/store' do
      ['nodes.txt', 'store-info.txt'].each do |f|
        download! f, "#{store_dir}/#{f}"
      end
    end

    # create all node dirs & fetch all can-info.txt files
    within '/dpr2store/repository' do
      repository_dir = "#{env}/#{h}/repository"
      `mkdir -p #{repository_dir}`
      canfiles = capture(:find, '.', '-type', 'f', '-name', 'can-info.txt').split
      canfiles = canfiles.map { |f| f.sub('./', '') }
      canfiles.each do |cf|
        cf_path = Pathname.new(cf)
        cf_basename = cf_path.basename
        cf_parent = cf_path.parent
        cf_parent_local = "#{repository_dir}/#{cf_parent}"
        `mkdir -p #{cf_parent_local}`
        download! cf, "#{cf_parent_local}/#{cf_basename}"
      end
    end
  end
end
