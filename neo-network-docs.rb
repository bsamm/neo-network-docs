require 'yaml'
require 'rom-neo4j'

class NeoNetworkDocs
  def self.generate
    data.each do |network|
      create_or_conn_db
      network.each do |app|
        create_node(app['name'])
        app['relationships'].each do |rel|
          # create relationship with label and create node, if it doesn't exist yet
          rel_name = rel.keys[0]
          rel.values[0].each do |node|
            puts app['name']
            puts rel_name
            puts node
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

  def self.create_or_conn_db
    puts "create db"
  end

  def self.create_node(app_name)
    puts "create app #{app_name}"
  end
end