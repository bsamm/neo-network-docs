require 'bundler/inline'
require 'yaml'

gemfile do
  source 'https://rubygems.org'
  gem 'rake'
  gem 'neo4j'
end

require 'neo4j/core/cypher_session/adaptors/http'

class NeoNetworkDocs
  def self.load_data

    options = {wrap_level: :proc} # Required to be able to use `Object.property` and `Object.relatedObject

    neo4j_adaptor = Neo4j::Core::CypherSession::Adaptors::HTTP.new('http://neo4j:password@localhost:7474')
    Neo4j::ActiveBase.on_establish_session { Neo4j::Core::CypherSession.new(neo4j_adaptor) }

    query("MATCH (n) DETACH DELETE n")

    data.each do |network|

      network_name = network[0].keys[0]
      network_data = network[0].values[0]

      query("CREATE CONSTRAINT ON (n:#{network_name.camelize}) ASSERT n.uuid IS UNIQUE")

      node_class = Class.new(Object) do
        include Neo4j::ActiveNode
        include Neo4j::Timestamps

        property :name, type: String
        property :server, type: String
        property :launch_doc, type: String
        property :notes, type: String
      end

      node = Object.const_set(network_name.camelize, node_class)

      network_data.each do |app|
        current_app = node.find_or_initialize_by(name: app['name'])
        current_app.assign_attributes(server: app['server']) if app['server'].present?
        current_app.assign_attributes(launch_doc: app['launch_doc']) if app['launch_doc'].present?
        current_app.assign_attributes(notes: app['notes']) if app['notes'].present?
        current_app.save
      end

      network_data.each do |app|
      
        source_app = node.find_or_create_by!(name: app['name'])
        if app.key?("relationships")
      
          app['relationships'].each do |rel|
      
            rel_name = rel.keys[0]
      
            rel_class = Class.new(Object) do
              include Neo4j::ActiveRel
      
              from_class :any
              to_class :any
      
              type rel_name.upcase
            end
      
            rel.values[0].each do |target_app_name|
      
              target_app = node.find_or_create_by!(name: target_app_name)
              begin
                custom_class = Object.const_get(rel_name.camelize)
              rescue NameError
                custom_class = Object.const_set(rel_name.camelize, rel_class)
              end
      
              if rel_name.scan(out_keywords_re).present?
                custom_class.create(from_node: source_app, to_node: target_app)
              elsif rel_name.scan(in_keywords_re).present?
                custom_class.create(from_node: target_app, to_node: source_app)
              else
                p "no keywords match. add in/out keywords to config.yml."
              end
      
            end
      
          end
        end
      end

    end

    p "data loaded successfully"
  end

  def self.data
    data = []
    Dir.glob('./networks/*.yml') do |yml_file|
      data << [File.basename(yml_file, ".*") => YAML.load(File.read(yml_file))]
    end
    data
  end

  def self.config
    YAML.load(File.read('./config.yml'))
  end

  def self.out_keywords_re
    Regexp.union(config['out_keywords'])
  end

  def self.in_keywords_re
    Regexp.union(config['in_keywords'])
  end

  def self.query(cypher_query)
    Neo4j::ActiveBase.current_session.query(cypher_query)
  end
end
