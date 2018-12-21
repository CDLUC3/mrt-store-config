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

before 'deploy', 'git:prompt_for_tag'
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

after 'deploy:set_current_revision', 'deploy:gen_store_info'
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
# TODO: symlink files etc.
end