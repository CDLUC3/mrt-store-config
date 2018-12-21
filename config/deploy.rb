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

## TODO: prompt for branch/tag?

namespace :deploy do
# TODO: symlink files etc.
end