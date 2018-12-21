# config valid for current version and patch releases of Capistrano
lock '~> 3.11.0'

role_account = 'dpr2store'
set :ssh_options, user: role_account, forward_agent: true

set :application, 'mrt-store-config'
set :deploy_to, "/apps/#{role_account}/apps/#{fetch(:application)}"
set :repo_url, 'git@github.com:cdlib/mrt-store-config.git'

# Use email address rather than username in revision log, if possible
git_user_email = `git config user.email`.to_s.strip
set :local_user, git_user_email.empty? ? fetch(:local_user) : git_user_email

env = fetch(:stage) # yes, 'stage' means 'environment' to Capistrano

namespace :git do
  desc 'Prompt for tag'
  task :prompt_for_tag do
    if (tag = ENV['TAG'])
      set :branch, tag
    else
      ask :branch, 'master'
    end
    puts ":branch set to #{fetch(:branch)}"
  end
end

namespace :deploy do
  desc 'Generate store-info.txt from ERB template'
  task :gen_store_info do
    on roles(:all) do |server|
      within "#{release_path}/config/src/#{env}/store" do
        # Use the deployed ERB, not the local copy
        store_info_template = download!('store-info.txt.erb')
        store_info_erb = ERB.new(store_info_template)
        store_info_txt = store_info_erb.result_with_hash(
          # These are set for each server in config/deploy/<ENV>.rb
          identifier: server.properties.identifier,
          base_uri: server.properties.base_uri
        )
        upload!(StringIO.new(store_info_txt), 'store-info.txt', mode: 0644)
      end
    end
  end

  namespace :symlink do
    desc 'Symlink nodes.txt and store-info.txt into mrtHomes directory'
    task :mrt_homes do
      mrt_homes_store_dir = Pathname.new("/apps/#{role_account}/mrtHomes/store")
      deployed_store_dir = Pathname.new("#{current_path}/config/src/#{env}/store")
      on roles(:all) do |_|
        within mrt_homes_store_dir do
          %w(nodes.txt store-info.txt).each do |filename|
            info "Checking #{filename} symlink"

            # See if symlink already exists
            if test('[', '-L', filename, ']')
              info "#{filename} already symlinked"
              next
            end

            # Move existing file, if present
            if test('[', '-f', filename, ']')
              new_name = "#{filename}.#{Time.now.to_i}"
              warn "#{filename} exists, but is a plain file; renaming to #{new_name}"
              execute(:mv, filename, new_name)
            end

            # Create symlink
            deployed_file_path = deployed_store_dir + filename
            info "Creating symlink to #{deployed_file_path}"
            execute(:ln, '-s', deployed_file_path, filename)
          end
        end
      end
    end

    desc 'Symlink can-info.txt files for individual nodes'
    task :can_info do
      repo_dir = Pathname.new("/apps/#{role_account}/repository")
      deployed_repo_dir = Pathname.new("#{current_path}/config/src/#{env}/repository")
      deployed_store_dir = Pathname.new("#{current_path}/config/src/#{env}/store")
      on roles(:all) do |_|
        # Use the deployed nodes.txt, not the local copy
        nodes_txt = download!(deployed_store_dir + 'nodes.txt')
        known_nodes = nodes_txt.gsub("#{repo_dir}/", '').split("\n")
        within(repo_dir) do
          known_nodes.each do |node|
            info "Checking can-info.txt symlink for #{node}"

            # Ensure node directory exists
            unless test('[', '-d', node, ']')
              info "Node directory #{repo_dir}/#{node} does not exist; creating"
              execute :mkdir, node
            end

            # See if symlink already exists
            can_info = Pathname.new(node) + 'can-info.txt'
            if test('[', '-L', can_info, ']')
              info "#{can_info} already symlinked"
              next
            end

            # Move existing file, if present
            if test('[', '-f', can_info, ']')
              new_name = "#{can_info}.#{Time.now.to_i}"
              warn "#{can_info} exists, but is a plain file; renaming to #{new_name}"
              execute(:mv, can_info, new_name)
            end

            # Create symlink
            deployed_can_info = deployed_repo_dir + can_info
            info "Creating symlink to #{deployed_can_info}"
            execute(:ln, '-s', deployed_can_info, can_info)
          end

          # See what extra node directories might be hanging around
          all_node_dirs = (capture(:ls, '-d', 'node*')).split
          (all_node_dirs - known_nodes).each do |unknown_node|
            warn "Unused node directory #{unknown_node}"
          end
        end
      end
    end
  end
end

before 'deploy', 'git:prompt_for_tag'
after 'deploy:set_current_revision', 'deploy:gen_store_info'
after 'deploy:symlink:release', 'deploy:symlink:mrt_homes'
after 'deploy:symlink:release', 'deploy:symlink:can_info'
