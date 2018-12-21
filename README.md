# mrt-store-config

Private configuration for [https://github.com/CDLUC3/mrt-store](mrt-store).

Capistrano deploys this repository to each server in the environment under 
`/apps/dpr2store/apps/mrt-store-config/`, with the usual `releases/current -> releases/<SHA hash>`
symlink structure, supporting rollbacks etc.

After deployment, the deploy script

1. uses the `identifier` and `base_uri` properties configured for each server to create a
   `store-info.txt` file from the deployed `store-info.txt.erb` (under `apps/mrt-store-config/current/config/src/<ENV>/store`).

2. creates the following symlinks, renaming existing (non-symlinked) files if necessary:

   | From `/apps/dpr2store/` | To `/apps/dpr2store/` |
   | --- | --- |
   | `mrtHomes/store/nodes.txt` | `apps/mrt-store-config/current/config/src/<ENV>/store/nodes.txt` |
   | `mrtHomes/store/store-info.txt`| `apps/mrt-store-config/current/config/src/<ENV>/store/store-info.txt` |
   | `repository/<NODE>/can-info.txt`| `apps/mrt-store-config/current/config/src/<ENV>/repository/<NODE>/can-info.txt`|

   A `can-info.txt` symlink is created for each node defined in `nodes.txt`; any existing node directories
   not listed in `nodes.txt` are ignored, but the script will print a warning.

## Usage

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

## Notes

The Capistrano deployment assumes that the current (local) user has SSH access to:

1. the `dpr2store` account on the target server, and
2. this repository. 

(If the local user has SSH access to the `dpr2store` account, and the `dpr2store` account has
a deploy key giving access to this repository, that will also work.)