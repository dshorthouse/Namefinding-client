require 'test/unit'
require File.expand_path(File.join(File.dirname(__FILE__), '..','lib','monkey_patches'))

MiniTest::Unit.autorun

class MonkeyPatchTest < Test::Unit::TestCase
  def setup
    @non_blank_object = String.new("test")
    @blank_object = String.new
    @string = String.new("Array")
  end

  def test_blank?
    assert @blank_object.empty?
    refute @non_blank_object.blank?
  end

  def test_constantize
    constant = @string.constantize
    assert_equal Array, constant
    ary = constant.new()
    assert_equal ary, []
  end
end
