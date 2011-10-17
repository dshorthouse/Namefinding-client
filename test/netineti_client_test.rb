require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '..','lib','netineti_client'))

class NetiTaxonFinderClientTest < Test::Unit::TestCase
  def setup
    @neti = NetiNetiClient.new
    @name = Name.new "Mus musculus"
  end
  
  def test_respond_to_find
    assert_respond_to @neti, 'find'
  end

  def test_add_name
    assert @neti.add_name(@name)
  end
end
