require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..','lib','name'))

describe Name do
  
  describe "without doing anything" do
    before :each do
      @find_me = "M. musculus"
      @name = Name.new(@find_me, {:start_position => 30, :scientific_name => "Mus musculus"})
    end
    
    it "should have figured out the end position" do
      @name.end_pos.should eq @name.start_pos + @find_me.length
    end
  end
  
  describe "unicode" do
    it "should handle unicode characters" do
      verbatim = "Slovenščina"
      name = Name.new(verbatim, {:start_position => 48193})
      name.verbatim.should eq verbatim
      name.end_pos.should eq name.start_pos + verbatim.length
    end
  end
end