# Project working with multiple raspberry pi's in a cluster

The `.ssh/` directory holds a mock SSH configuration to help you create your own setup.
See [`.ssh/README.md`](./.ssh/README.md) for the step-by-step guide.

Your `.ssh/config` file is central in this project. It will be used together with a file named `nodes.conf`.
Create a file named `nodes.conf` in the root of the project and list the the name of the nodes that the project should use, one node per line. The name of the node should be the same node name you use in your `.ssh/config`.
