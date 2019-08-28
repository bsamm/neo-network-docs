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

    query("MATCH (n) DETACH DELETE n")
    query("CREATE CONSTRAINT ON (n:App) ASSERT n.uuid IS UNIQUE")

    data.each do |network|

      network.each do |app|
        App.find_or_create_by!(
          name: app['name']
        )
      end

      network.each do |app|
        source_app = App.find_or_create_by!(name: app['name'])
        if app.key?("relationships")
          app['relationships'].each do |rel|
            rel_name = rel.keys[0]
            rel.values[0].each do |target_app_name|
              target_app = App.find_or_create_by!(name: target_app_name)
              ExportsDataTo.create(from_node: source_app, to_node: target_app)
            end
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

  def self.query(cypher_query)
    Neo4j::ActiveBase.current_session.query(cypher_query)
  end
end

class App
  include Neo4j::ActiveNode
  include Neo4j::Timestamps

  has_many :out, :exports, model_class: :App, rel_class: :ExportsDataTo
  has_many :in, :imports, model_class: :App, rel_class: :ImportsDataFrom

  property :name, type: String
end

class ExportsDataTo
  include Neo4j::ActiveRel

  from_class :App
  to_class :App
end

class ImportsDataFrom
  include Neo4j::ActiveRel

  from_class :App
  to_class :App
end