require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '..','lib','finder_client'))

class FinderClientTest < Test::Unit::TestCase
  def setup
    @finder_client = FinderClient.new('taxon_config.yml')
    @name = Name.new("M. musculus")
  end

  def test_find
    assert_raises(RuntimeError, "Subclass must implement find") do
      @finder_client.find('test')
    end
  end
  
  def test_add_name
    assert @finder_client.add_name(@name)
  end
end
