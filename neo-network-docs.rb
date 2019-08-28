require 'bundler/inline'
require 'yaml'

gemfile do
  source 'https://rubygems.org'
  gem 'rake'
  gem 'neo4j'
end

require 'neo4j/core/cypher_session/adaptors/http'

class NeoNetworkDocs
  def self.generate

    options = {wrap_level: :proc} # Required to be able to use `Object.property` and `Object.relatedObject

    neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new('http://neo4j:password@localhost:7474')
    Neo4j::ActiveBase.on_establish_session { Neo4j::Core::CypherSession.new(neo4j_adaptor) }

    Neo4j::ActiveBase.current_session.query("CREATE CONSTRAINT ON (n:App) ASSERT n.uuid IS UNIQUE")

    data.each do |network|
      network.each do |app|
        App.create(name: app['name'])
        app['relationships'].each do |rel|
          # create relationship with label and create node, if it doesn't exist yet
          rel_name = rel.keys[0]
          rel.values[0].each do |node|
            # puts app['name']
            # puts rel_name
            # puts node
          end
        end
      end
    end
  end

  def self.data
    data = []
    Dir.glob('./networks/*.yml') do |yml_file|
      data << YAML.load(File.read(yml_file))
    end
    data
  end

end

class App
  include Neo4j::ActiveNode
  include Neo4j::Timestamps

  property :name, type: String
end

class Rel
  include Neo4j::ActiveRel
  include Neo4j::Timestamps
end