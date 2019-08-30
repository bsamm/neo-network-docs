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

    clear_database
    create_all_nodes
    create_all_rels
    p "data loaded successfully"
  end

  def self.clear_database
    query("MATCH (n) DETACH DELETE n")
  end

  def self.create_all_nodes
    data.each do |network|
      network_name = get_network_name(network)
      network_data = get_network_data(network)

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
    end
  end

  def self.create_all_rels
    data.each do |network|
      network_data = get_network_data(network)
    
      network_data.each do |app|
        source_app = get_node_class(get_network_name(network)).find_or_create_by!(name: app['name'])
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
    
              node_labels.each do |n|
                begin 
                  target_app = get_node_class(n).find_or_initialize_by(name: target_app_name)  
                rescue NameError
                  query("CREATE CONSTRAINT ON (n:#{n.camelize}) ASSERT n.uuid IS UNIQUE")
                  node = Object.const_set(n.camelize, node_class)
                  target_app = get_node_class(n).find_or_create_by!(name: target_app_name)  
                end
                @target_app = target_app if target_app.created_at.present?
              end
    
              begin
                custom_class = Object.const_get(rel_name.camelize)
              rescue NameError
                custom_class = Object.const_set(rel_name.camelize, rel_class)
              end
    
              if rel_name.scan(out_keywords_re).present?
                custom_class.create(from_node: source_app, to_node: @target_app)
              elsif rel_name.scan(in_keywords_re).present?
                custom_class.create(from_node: @target_app, to_node: source_app)
              else
                p "no keywords match. add in/out keywords to config.yml."
              end
    
            end
    
          end
        end
      end
    
    end
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

  def self.node_labels
    node_labels = []
    data.map { |n| node_labels << n[0].keys[0] }
    node_labels
  end

  def self.get_network_name(network)
    network[0].keys[0]
  end

  def self.get_network_data(network)
    network[0].values[0]
  end

  def self.get_node_class(node_class_name)
    node_class_name.camelize.constantize
  end
end
