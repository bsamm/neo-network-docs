# neo-network-docs

A simple and human-readable way to load your network diagram into neo4j for visualization and analysis.

## Setup on macOS

1. Install neo4j
2. Duplicate the `network.yml` file and rename with the name of your network (aka database). Also fill in some of the data.
3. Run:

```
>irb
>require "./neo-network-docs.rb"
>NeoNetworkDocs.generate
```
