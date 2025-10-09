# Project working with multiple raspberry pi's in a cluster
[![License: CeCILL-B](https://img.shields.io/badge/License-CeCILL--B-green.svg?style=for-the-badge)](LICENSE)

The `.ssh/` directory holds a mock SSH configuration to help you create your own setup.
See [`.ssh/README.md`](./.ssh/README.md) for the step-by-step guide.

Your `.ssh/config` file is central in this project. It will be used together with a file named `nodes.conf`.
Create a file named `nodes.conf` in the root of the project and list the the name of the nodes that the project should use, one node per line. The name of the node should be the same node name you use in your `.ssh/config`.

.ssh/config.example
```ssh config
# --- PI Cluster ---
Host pi-node-1
  Hostname 10.10.10.101
  user your_username
  IdentityFile ~/.ssh/id_ed25519

Host pi-node-2
  HostName 10.10.10.102
  user you_username
  IdentityFile ~/.ssh/id_ed25519

Host pi-node-3
  HostName 10.10.10.103
  user your_username
  IdentityFile ~/.ssh/id_ed25519

Host pi-node-4
  HostName 10.10.10.104
  user your_username
  IdentityFile ~/.ssh/id_ed25519
```

nodes.conf.example
```bash
#!/usr/bin/env bash
# Static list, one node per line
# each node name should match with ssh aliases in your .ssh/config
pi-node-1
pi-node-2
pi-node-3
pi-node-4
```

## Quick Start

1. Copy `nodes.conf.example` -> `nodes.conf` and list your Pi aliases from your `~/.ssh/config`
2. `cd bash && ./main_menu.sh`
3. Follow the TUI: Generate -> Deploy -> Start


The bash directory holds the bash version for generating the cluster.
`chmod +x main_menu.sh` and run the main_menu script by executing `./main_menu.sh`

## Community and License
Copyright (c) 2025 vardaasen
[![License: CeCILL-B](https://img.shields.io/badge/License-CeCILL--B-green.svg?style=for-the-badge)](LICENSE)

see [CONTRIBUTING.md](CONTRIBUTING.md).


