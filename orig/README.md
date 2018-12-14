Original `nodes.txt`, `store-info.txt`, and `can-info.txt` configuration
files as retrieved from Storage servers.

To update, run

```
REMOTE_USER=<your username> ./fetch_configs.rb
```

Note that this will **not** clear out any files already downloaded here
that no longer exist on the remote servers.
