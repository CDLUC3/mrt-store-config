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

## Notes

The Capistrano deployment and the `fetch-configs.rb` script below both assume that
the current (local) user has SSH access to:

1. the `dpr2store` account on the target server, and
2. this repository. 

(If the local user has SSH access to the `dpr2store` account, and the `dpr2store` account has
a deploy key giving access to this repository, that will also work.) (Though how you got here
in that case is a question.)

## Preparatory scripts (`bin` directory)

⚠️ **Note:** these scripts were used to generate this config repository, and you should not need
to run them again, but they're included here for historical purposes.

## `fetch-configs.rb` 

Downloads original `nodes.txt`, `store-info.txt`, and `can-info.txt` 
configuration files from storage servers to (local) `orig` directory.

Note that this script seems to sometimes fail with an **SSHKit::Runner:ExecuteError** **No route to host**
when run over the VPN. Running it again seems to solve the problem.

## `diff-nodes-txt.rb`

Checks to make sure the `nodes.txt` files downloaded for each environment/node 
combination contain identical active entries (order is ignored, commented lines
are ignored)

## `diff-can-info.rb`

Checks to make sure the `can-info.txt` files downloaded for each environment/node 
combination are identical.

## `diff-store-info.rb`

Checks to make sure the `store-info.txt` files downloaded for each environment/node
are consistent (identical apart from the hostname).

## `gen-config-src.rb`

Generates [`config/src`](config/src) files for each environment based on the files downloaded into
`orig`. If the downloaded files are not consistent between servers (as determined by
the `diff-<FILENAME>.rb` scripts above), exits with an error.