# encoding: UTF-8

require 'net/http'
require 'uri'

require File.expand_path(File.join(File.dirname(__FILE__), 'finder_client'))

class NetiNetiClient < FinderClient
  def initialize(config_file="netineti_config.yml")
    super 
  end
  
  def find(input, from_web_form=false)
    # the form does not get sent if input is nil or empty
    return [] if input.nil? || input.empty?
    
    response = Net::HTTP.post_form URI.parse("http://#{@host}:#{@port}/"), {"data" => input.to_s, "from_web_form" => from_web_form.to_s}
    raise ClientError, "Received bad response from NetiNeti" unless response.is_a? Net::HTTPSuccess
    char = from_web_form ? "\n" : '|'

    response.body.split(char).collect do |info|
      name, offset_start = info.split(',')
      verbatim_name = name.sub(/\[.*\]/, '.')
      Name.new(verbatim_name, :scientific_name => name, :start_position => offset_start.to_i)
    end
  end
end
