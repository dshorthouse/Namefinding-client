require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
require File.expand_path(File.join(File.dirname(__FILE__), '..','lib','taxon_finder_client'))

describe 'TaxonFinderClient' do
  before do
    @client = TaxonFinderClient.new
  end
  describe "when given a blank input" do
    it "should immediately return a blank array when passed nil" do
      @client.find(nil).should eq Array.new
    end
    it "should immediately return a blank array when passed ''" do
      @client.find('').should eq Array.new
    end
  end

  describe "when given some garbage input" do
    it "should come back empty" do
      @client.find('test').should be_empty
    end
  end

  describe "when given some good input" do    
    it "should return an array of names" do
      verbatim = ['Selenochlamys', 'Trigonochlamydidae']
      names = @client.find('Some text that includes Selenochlamys ysbryda, and also S. ysbryda, and also Trigonochlamydidae')
      names.each do |name|
        verbatim.should include name.verbatim
        verbatim.delete name.verbatim
      end
      verbatim.length.should eq 0
    end
    
  end
  
  describe "when given some semicolons in the input" do
    it "should not immediately end when it hits a semicolon" do
      text = "This is some Mus musculus test that; ; should not contain Selenochlamys or something."
      names = @client.find(text).collect{|name| name.verbatim}
      names.should include 'Mus musculus'
      names.should include 'Selenochlamys'
    end
    
    it "should find the proper name and offsets when there are semicolons" do
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
  
  describe "some crazy offset tests" do
    taxonomy = {:kingdom => %w=Animalia Bacteria=,
                :phylum =>  %w=Mollusca Chordata=,
                :class =>   %w=Insecta Mammalia=,
                :order =>   %w=Diptera Primates=,
                :family =>  %w=Drosophilidae Hominidae=,
                :genus  =>  %w=Drosophila Homo=,
                :species => %w=melanogaster sapiens=,
                :genus_species => ['Drosophila melanogaster','Homo sapiens']}
                
    taxonomy.each_pair do |key, value|
      it "should return the proper offsets of a #{key}" do
        text = "this is some #{value[0]} text with #{value[1]} in it"
        names = @client.find(text)
        names.each do |name|
          text[name.start_pos, name.end_pos-name.start_pos].should eq name.verbatim
        end
      end
    end
    
    it "should return the proper offsets when there are characters around a name" do
      family = %w=Drosophilidae Hominidae=
      text = "one %@#{family[0]} two @@#{family[0]} red #{family[0]} blue ()#{family[1]};"
      names = @client.find(text)
      names.each do |name|
        text[name.start_pos, name.end_pos-name.start_pos].should eq name.verbatim
      end
      
    end
    
    it "should return proper offsets when there are semicolons" do
      text = "This is some Mus musculus test; that; should not con;tain Selenochlamys but wtf"
      names = @client.find(text)
      names.each do |name|
        text[name.start_pos,name.end_pos-name.start_pos].should eq name.verbatim
      end
    end
    
    it "should return the correct offsets from the whole html document" do
      find_me = "Passer domesticus"
      html = "<html><head><title>hey</title></head><body><span>this is Homo sapiens</span> test. <strong>Mus musculus</strong> it should only find this one #{find_me} </body></html>"
      names = @client.find(html)
      names[0].start_pos.should eq html.index(find_me)
      names[0].end_pos.should eq html.index(find_me) + find_me.length
    end
    
    it "should be fine with strange whitespace" do
      find_me = "Homo sapiens"
      text = "    \t \t  \n  this is \n\n#{find_me} is \n\na real test"
      names = @client.find(text)
      names.first.start_pos.should eq text.index(find_me)
      names.first.end_pos.should eq text.index(find_me) + find_me.length
      text[names.first.start_pos,find_me.length].should eq find_me
    end

  end
  
  describe "bug number 355" do
    it "should give the correct offsets for the input" do
      text = File.open('species_05.txt','r').read
      ghost_slugs_are_crazy = @client.find(text)
      ghost_slugs_are_crazy.each do |name|
        text[name.start_pos,name.end_pos-name.start_pos].should eq name.verbatim
      end
    end
  end
end
