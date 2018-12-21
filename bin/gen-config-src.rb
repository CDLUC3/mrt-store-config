#!/usr/bin/env ruby

require 'pathname'
require 'fileutils'

############################################################
# Accessors

def envs
  @envs ||= %w[dev stg prd]
end

def project_dir
  @project_dir ||= Pathname.new(__dir__).parent
end

def deploy_dir
  @deploy_dir ||= project_dir + 'config/deploy'
end

def orig_dir
  @orig_dir ||= project_dir + 'orig'
end

def config_dir
  @config_dir ||= project_dir + 'config'
end

############################################################
# Utility methods

def full_env(env)
  @full_envs ||= {
    dev: 'development',
    stg: 'stage',
    prd: 'production'
  }
  @full_envs[env.to_sym]
end

def config_src_dir_for(env)
  (config_dir + 'src') + full_env(env)
end

def first_host_dir_for(env)
  @host_dirs ||= {}
  @host_dirs[env] ||= begin
    env_dir = orig_dir + env
    Pathname.new(Dir[env_dir + '*'].first)
  end
end

def nodes_txt_lines(env)
  @nodes_txt_lines ||= {}
  @nodes_txt_lines[env] ||= begin
    orig_host_dir = first_host_dir_for(env)
    orig_nodes_txt = orig_host_dir + 'store/nodes.txt'
    File.read(orig_nodes_txt).gsub(/^#[^\n]+\n/, '').split.sort.reject { |l| l.to_s.strip.empty? }
  end
end

def nodes(env)
  nodes_txt_lines(env).map do |line|
    line[%r{repository/(node[0-9]+[A-Za-z]*)}, 1]
  end.compact
end

def store_info_erb_lines(env)
  orig_host_dir = first_host_dir_for(env)
  orig_nodes_txt = orig_host_dir + 'store/store-info.txt'
  File.read(orig_nodes_txt).gsub(/^#[^\n]+\n/, '').split.map(&method(:to_erb_line))
end

def to_erb_line(line)
  return "identifier: <%= identifier %>" if line.start_with?('identifier:')
  return "baseURI: <%= base_uri %>" if line.start_with?('baseURI:')
  line
end

############################################################
# Main program

unless File.directory?(orig_dir)
  $stderr.puts("Directory #{orig_dir} not found; did you run fetch-configs.rb?")
  exit(1)
end

Dir.chdir(project_dir)

# exit(1) unless system('bin/fetch_configs.rb')
exit(1) unless system('bin/diff-nodes-txt.rb')
exit(1) unless system('bin/diff-store-info.rb')
exit(1) unless system('bin/diff-can-info.rb')

FileUtils.remove_dir(config_dir + 'src', true)

envs.each do |env|
  puts "Generating config files for environment: #{env}"
  config_src_dir = config_src_dir_for(env)
  orig_host_dir = first_host_dir_for(env)

  store_dir = config_src_dir + 'store'
  puts "Creating #{store_dir}"
  FileUtils.mkdir_p(store_dir)

  nodes_txt = store_dir + 'nodes.txt'
  puts "Writing #{nodes_txt}"
  File.open(nodes_txt, 'w') do |f|
    f.puts(nodes_txt_lines(env).join("\n"))
  end

  store_info_txt_erb = store_dir + 'store-info.txt.erb'
  puts "Writing #{store_info_txt_erb}"
  File.open(store_info_txt_erb, 'w') do |f|
    f.puts(store_info_erb_lines(env).join("\n"))
  end

  repository_dir = config_src_dir + 'repository'
  FileUtils.mkdir_p(repository_dir)
  orig_repository_dir = orig_host_dir + 'repository'
  nodes(env).each do |node|
    puts "#{env}: #{node}"
    orig_node_dir = orig_repository_dir + node
    new_node_dir = repository_dir + node
    FileUtils.mkdir_p(new_node_dir)
    orig_can_info = orig_node_dir + 'can-info.txt'
    new_can_info = new_node_dir + 'can-info.txt'
    puts "Copying #{orig_can_info} to #{new_can_info}"
    FileUtils.cp(orig_can_info, new_can_info)
  end
end