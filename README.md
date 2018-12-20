# mrt-store-config

Private configuration for [https://github.com/CDLUC3/mrt-store](mrt-store).

# Scripts (`bin` directory)

## `fetch-configs.rb` 

Downloads original `nodes.txt`, `store-info.txt`, and `can-info.txt` 
configuration files as retrieved from Storage servers. To update, run

```
REMOTE_USER=<your username> bin/fetch_configs.rb
```

Note that this will **not** clear out any files already downloaded here
that no longer exist on the remote servers.

## `diff-can-info.rb`

Checks to make sure the `can-info.txt` files downloaded for each environment/node 
combination are identical.

## `diff-store-info.rb`

Checks to make sure the `store-info.txt` files downloaded for each environment/node
are consistent (identical apart from the hostname).