# Preparatory scripts (`bin` directory)

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