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
    env = fetch(:stage) # yes, 'stage' means 'environment' to Capistrano
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
      env = fetch(:stage) # yes, 'stage' means 'environment' to Capistrano
      deployed_store = Pathname.new("#{current_path}/config/src/#{env}/store")
      mrt_homes_store = Pathname.new("/apps/#{role_account}/mrtHomes/store")
      on roles(:all) do |_|
        within mrt_homes_store do
          %w(nodes.txt store-info.txt).each do |filename|
            if test('[', '-L', filename, ']')
              info "#{filename} already symlinked"
              next
            end
            if test('[', '-f', filename, ']')
              new_name = "#{filename}.#{Time.now.to_i}"
              warn "#{filename} exists, but is a plain file; renaming to #{new_name}"
              execute(:mv, filename, new_name)
            end
            deployed_file_path = deployed_store + filename
            info "Creating symlink to #{deployed_file_path}"
            execute(:ln, '-s', deployed_file_path, filename)
          end
        end
      end
    end

    # TODO: symlink individual nodes
  end
end

before 'deploy', 'git:prompt_for_tag'
after 'deploy:set_current_revision', 'deploy:gen_store_info'
after 'deploy:symlink:release', 'deploy:symlink:mrt_homes'
