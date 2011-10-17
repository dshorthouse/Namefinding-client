require 'socket'
require 'yaml'

require File.expand_path(File.dirname(__FILE__) + '/name')
require File.expand_path(File.dirname(__FILE__) + '/monkey_patches')

class FinderClient
  class ClientError < Exception; end
  
  attr_reader :host
  attr_reader :port
  
  def initialize(config_file)
    configuration = YAML.load_file(File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', config_file)))
    @host = configuration['host']
    @port = configuration['port']
    @names = Array.new
  end
  
  def find(str, from_web_form=false)
    raise "Subclass must implement find"
  end
  
  def add_name(name)
    @names << name
  end
end
