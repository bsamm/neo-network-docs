# neo-network-docs

A simple and human-readable way to load your network diagram into neo4j for visualization and analysis.

## Setup on macOS

1. Install neo4j: `rake neo4j:install`. This will create the db dir with an instance of neo4j in the project.
2. Start/stop the db server: `rake neo4j:start` and `rake neo4j:stop`
3. Go to `http://localhost:7474`
4. Duplicate the `zoo.yml` file and rename with the name of your networks (aka database in neo4j). Also fill in some of the data based on the examples.
5. Load the data:

```
>irb
>require "./neo-network-docs.rb"
>NeoNetworkDocs.load_data
```
