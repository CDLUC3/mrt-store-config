#!/usr/bin/env ruby

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

def project_dir
  @project_dir ||= Pathname.new(__dir__).parent
end

def deploy_dir
  @deploy_dir ||= project_dir + 'config/deploy'
end

############################################################
# Utility methods

def fq(host)
  "#{host}.cdlib.org"
end

def hosts_for(env)
  env_to_hosts[env]
end

def identifier(env, host)
  if env == :dev
    # TODO: why is this different?
    return 'mrtstore2-dev.cdlib.org:25121'
  end
  "#{fq(host)}:35121"
end

def base_uri(host)
  "http://#{fq(host)}:35121"
end

def full_env(env)
  @full_envs ||= {
    dev: 'development',
    stg: 'staging',
    prd: 'production'
  }
  @full_envs[env]
end

############################################################
# Main program

env_to_hosts.each do |env, hosts|
  FileUtils.mkdir_p(deploy_dir)
  cap_env_rb = deploy_dir + "#{full_env(env)}.rb"
  puts "Writing #{cap_env_rb}"
  File.open(cap_env_rb, 'w') do |f|
    host_configs = hosts.map do |host|
      <<~CONF
        server "#{fq(host)}",
          identifier: "#{identifier(env, host)}",
          base_uri: "#{base_uri(host)}"
      CONF
    end
    f.puts(host_configs.join("\n"))
  end
end