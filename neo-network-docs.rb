require 'yaml'
require 'rom-neo4j'

class NeoNetworkDocs
  def self.generate
    data.each do | app |
      p app['name']
    end
    # create database if it doesn't exist
    # loop through data and create nodes and relationships
    #

  end

  def self.data
    YAML.load(File.read("./networks/network.yml"))
  end
end