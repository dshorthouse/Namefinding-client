require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..','lib','netineti_client'))

describe 'NetiNetiClient' do
  before do
    @client = NetiNetiClient.new
    FakeWeb.register_uri(:post, "http://#{@client.host}:#{@client.port}", :body => '')
  end
  
  describe "when given a blank input" do
    it "should immediately return a blank array" do
      @client.find(nil).should eq Array.new
    end
  end
  
  describe "when given some garbage input" do
    it "should send a post to the netineti server" do
      @client.find('test').should be_empty
    end
  end
  
  describe "when the netineti server returns not a 200" do
    it 'should raise FinderClient::ClientError' do
      FakeWeb.register_uri(:post, "http://#{@client.host}:#{@client.port}", :status => ['500', "Internal Server Error"])
      lambda { @client.find('test') }.should raise_error FinderClient::ClientError
    end
  end
  
  describe "some semicolon input tests" do
    before do
      FakeWeb.clean_registry
    end
    
    it "should work properly with semicolons" do
      text = 'Some text that includes Selenochlamys ysbryda and also S. ysbryda; and also Trigonochlamydidae'
      names = @client.find(text)
      verbatim = ['S. ysbryda', 'Selenochlamys ysbryda', 'Trigonochlamydidae']
      names.each do |name|
        text[name.start_pos,name.end_pos-name.start_pos].should eq name.verbatim
      end
    end
    
    it "should have the proper offsets with semicolon'd text" do
      names = ["Mus musculus", "Homo sapiens"]
      text = "; ; ; ; this ; is proof;; #{names[0]} ;;;; that semicolons; don't; ;affect; the results #{names[1]} !!!:;;;;!;;;"
      ret = @client.find(text)
      names.each_with_index do |name, i|
        start = text.index(name)
        fin = start + name.length
        ret[i].start_pos.should eq start
        ret[i].end_pos.should eq fin
        ret[i].verbatim.should eq name
      end
    end
    
  end
  
  describe "when given some good input" do
    before do
      FakeWeb.register_uri(:post, "http://#{@client.host}:#{@client.port}", :body => "Selenochlamys ysbryda,24|S. ysbryda|Trigonochlamydidae")
    end
    
    it "should return an array of names" do
      names = @client.find('Some text that includes Selenochlamys ysbryda, and also S. ysbryda, and also Trigonochlamydidae')
      verbatim = ['S. ysbryda', 'Selenochlamys ysbryda', 'Trigonochlamydidae']
      names.each do |name|
        verbatim.should include name.verbatim
      end
    end
  end
  

end
