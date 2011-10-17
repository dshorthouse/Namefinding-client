require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '..','lib','name'))

MiniTest::Unit.autorun

class NameTest < Test::Unit::TestCase
  def setup
    @name_with_pos = Name.new('M. musculus', {start_position: 49, scientific_name: 'Mus musculus'})
    @name_with_pos_2 = Name.new('M. musculus', {start_position: 49, scientific_name: 'Mus musculus'})
    @name_without_pos = Name.new('M. musculus')
  end

  def test_end_pos_is_correct
    assert_equal 59, @name_with_pos.end_pos
  end

  def test_eql?
    assert @name_with_pos.eql? @name_with_pos_2
    refute @name_with_pos.eql? @name_without_pos
  end
end
