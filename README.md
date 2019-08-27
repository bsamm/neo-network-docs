# neo-network-docs

A simple and human-readable way to load your network diagram into neo4j for visualization and analysis.

## Setup on macOS

1. Install neo4j: `brew install neo4j`
2. Duplicate the `network.yml` file and rename with the name of your networks (aka database in neo4j). Also fill in some of the data based on the examples.
3. Load the data:

```
>irb
>require "./neo-network-docs.rb"
>NeoNetworkDocs.generate
```
