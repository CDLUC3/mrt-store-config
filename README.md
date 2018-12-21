# mrt-store-config

Private configuration for [https://github.com/CDLUC3/mrt-store](mrt-store).

## Usage

⚠️ **Work in progress**

1. Make sure any changes to this project have been pushed to GitHub. (Capistrano always
   deploys from the most recent GitHub release, regardless of any changes made in the
   repository you run it from.)
2. From the project root:

   ```
   [TAG=<TAG>] bundle exec cap <ENV> deploy
   ```

   where `<ENV>` is one of `development`, `stage`, `production` (as defined by the scripts
   in the [`config/deploy`](config/deploy) directory), and `<TAG>` is an optional Git tag
   for this repository.

Capistrano deploys this repository to each server in the environment under 
`/apps/dpr2store/apps/mrt-store-config/`, with the usual `releases/current -> releases/<SHA hash>`
symlink structure, supporting rollbacks etc.

## Notes

The Capistrano deployment and the `fetch-configs.rb` script below both assume that
the current (local) user has SSH access to:

1. the `dpr2store` account on the target server, and
2. this repository. 

(If the local user has SSH access to the `dpr2store` account, and the `dpr2store` account has
a deploy key giving access to this repository, that will also work.)