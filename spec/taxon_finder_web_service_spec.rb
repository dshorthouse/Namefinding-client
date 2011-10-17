# coding: utf-8
require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))
  
describe 'The TaxonFinderWebService app' do 
  include Rack::Test::Methods
  
  def app
    Sinatra::Application
  end
  
  CLIENTS = ['neti','taxonfinder']
  FORMATS = ['xml', 'json']
  
  describe 'server' do
    it "should have a form on the home page" do
      get '/'
      last_response.status.should eq 200
      last_response.body.should include "<form"
    end
    
    it 'should return a 404 with an unknown url' do
      get '/404!!!'
      last_response.status.should eq 404
    end
  end
    
  describe  'offset specs' do
    name = "Mus musculus"
    texts = ["dksjlf sldkjfl sdkljf slkdjf lksdj flksjd flksjdf          lskdjflksdj #{name} this buhh",
              "a       dksjlf sldkjfl sdkljf slkdjf lksdj flksjd flksjdf          lskdjflksdj #{name} this buhh"]
    
    texts.each do |text|
      CLIENTS.each do |client|
        it "should return the proper offset for the given text and given client: #{client}" do
          start = text.index(name)
          finish = text.index(name) + name.length
          get "/find?input=#{URI.escape text}&type=text&format=xml&client=#{client}"
          last_response.body.should include "<offset start=\"#{start}\" end=\"#{finish}\"/>"
          text[start,finish-start].should eq name
        end
      end
    end
  end
  
  describe 'url specs' do
    before do
      REAL_URL = URI.escape "http://www.bacterio.cict.fr/d/desulfotomaculum.html"
      FakeWeb.register_uri(:get, REAL_URL, :body => "Desulfosporosinus orientis and also Desulfotomaculum alkaliphilum win")
    end
    
    it "should return a verbatim name when a valid species name is identified in the supplied url" do
      get "/find?input=#{REAL_URL}&type=url&format=xml"
      last_response.body.should include "<verbatim>Desulfosporosinus orientis</verbatim>"
      last_response.body.should include "<verbatim>Desulfotomaculum alkaliphilum</verbatim>"
    end
  end
  
  describe "html tests" do
    CLIENTS.each do |client|
      describe "#{client}" do
        before do
          FakeWeb.clean_registry
        end
        
        it "given some html it should only use the body text" do
          find_these = ['Drosophila melanogaster', 'Mus musculus', 'Homo sapiens']
          html = "<html><head><title>hey</title></head><body><span>this is #{find_these[0]}</span> test. <strong>#{find_these[1]}</strong> it should only find this one #{find_these[2]} test</body></html>"
          send = URI.escape(html, Regexp.new("[^#{URI::REGEXP::PATTERN}]"))
          
          get "/find?input=#{send}&type=text&format=xml&client=#{client}"
          last_response.should be_ok
          
          find_these.each do |name|
            last_response.body.should include 
"    <verbatim>#{name}</verbatim>\n
    <dwc:scientificName>#{name}</dwc:scientificName>\n
    <offset start=\"#{html.index(name)}\" end=\"#{html.index(name) + name.length}\"/>"
          end
        end
      end
    end
  end
  
  describe "text tests" do
    
    CLIENTS.each do |client|
      describe "#{client}" do
        before do
          @name = "Mus musculus"
          @abbr = "M. musculus"
          @unescaped_text = "first ;we find #{@name} and then we find #{@abbr} again"
          @text = URI.escape(@unescaped_text, Regexp.new("[^#{URI::REGEXP::PATTERN}]"))
        end
        
        it "should return a verbatim name when a valid species name is identified in text" do
          get "/find?input=#{@text}&type=text&format=xml&client=#{client}"
          last_response.body.should include "<verbatim>#{@abbr}</verbatim>"
          last_response.body.should include "<verbatim>#{@name}</verbatim>"
        end
    
        it "should display both sci. name and verbatim when an abbreviated species name is supplied" do
           get "/find?input=#{@text}&type=text&format=xml&client=#{client}"
           last_response.body.should include "<verbatim>#{@abbr}</verbatim>"
           last_response.body.should include "<dwc:scientificName>#{@name}</dwc:scientificName>"
         end

         it "should return the proper offset" do
           start_name = @unescaped_text.index(@name)
           finish_name = start_name + @name.length
           start_abbr = @unescaped_text.index(@abbr)
           finish_abbr = start_abbr + @abbr.length
           get "/find?input=#{@text}&type=text&format=xml&client=#{client}"
           last_response.body.should include "<offset start=\"#{start_name}\" end=\"#{finish_name}\"/>"
           last_response.body.should include "<offset start=\"#{start_abbr}\" end=\"#{finish_abbr}\"/>"
         end
     
         it "should not return any children of the names element if there are no names found" do
           text = URI.escape "What a nice weather is today!"
           get "/find?input=#{text}&type=text&format=xml&client=#{client}"
           last_response.status.should eq 200
           last_response.body.should include %(xmlns="http://globalnames.org/namefinder")
           last_response.body.should include %(xmlns:dwc="http://rs.tdwg.org/dwc/terms/")
         end
     
         it "should find names buried within HTML" do
           names = ["Mus musculus", "Homo sapiens"]
           body = "<html><body>There is a <ul><li> #{names[0]} </li><li> #{names[1]} </li></ul> in my house</body></html>"
           body = "There is a #{names[0]} #{names[1]} in my house"
           text = URI.escape body
           get "/find?input=#{text}&type=text&format=xml&client=#{client}"
           last_response.status.should eq 200
           names.each do |name|
             start = body.index(name)
             finish = start + name.length
             last_response.body.should include "<offset start=\"#{start}\" end=\"#{finish}\"/>"
             last_response.body.should include "<verbatim>#{name}</verbatim>"
           end
         end
       end
     end
  end
   
  describe "unicode support" do
    before do
      ic = Iconv.new('windows-1252','utf-8')
      @test_string = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789ŠšŽž"
      @test_string = ic.iconv(@test_string + ' ')[0..-2]
      @test_string = URI.escape @test_string
    end
    
    CLIENTS.each do |client|
      it "should not fail with non-unicode characters from text" do
        get "/find?input=#{@test_string}&type=text&format=xml&client=#{client}"
        last_response.status.should eq 200
      end
    end
  end
  
  describe "type response specs" do
    it "should return xml if the format isn't provided" do
      get "/find?input=a&type=text"
      last_response.body.should include "<?xml"
    end
    
    it "should return xml if the format is unknown" do
      get "/find?input=&type=text"
      last_response.body.should include  "<?xml"
    end
    
    it "should return xml if xml is requested" do
      get "/find?input=&type=text&format=xml"
      last_response.body.should include  "<?xml"
    end
    
    it "should properly set the content headers for xml" do
      get "/find?input=&type=text&format=xml"
      last_response.headers['Content-Type'].should include  "application/xml"
    end
    
    it "should return json if json is requested" do
      get "/find?input=sdfgr&type=text&format=json"
      last_response.body.should include  '{"names":'
    end
    
    it "should properly set the content headers for json" do
      get "/find?input=&type=text&format=json"
      last_response.headers['Content-Type'].should include  "application/json"
    end
  end
  

  describe "response tests" do
    FAKE_301 = URI.escape "http://www.fake301.com"
    FAKE_302 = URI.escape "http://www.fake302.com"
    NOTHING = URI.escape "http://www.nothing.com"
    STATUS_CODES = [
     ['301','Permanent Redirect',FAKE_301],
     ['302','Temp Redirect',FAKE_302],
     ['200','Great Success'],
     ['418',"I'm a teapot"],
     ['999','this is fake'],
     ['500','Server Error'],
    ]
    TEST = URI.escape "http://www.responsetest.com/"
    
    before :all do
      FakeWeb.register_uri(:get, FAKE_301, :body => "the Latrodectus hasselti is freaking gross")
      FakeWeb.register_uri(:get, FAKE_302, :body => "the Ursus maritimus is freaking AWESOME!")
      FakeWeb.register_uri(:get, NOTHING, :body => "nothing")
      FakeWeb.register_uri(:get, TEST,
        STATUS_CODES.map {|code, message, loc| {:body => 'blank', :status => [code, message], :location => loc}})
    end
    
      it "should follow 301 status code" do
        get "/find?input=#{TEST}&type=url&format=xml&client=taxonfinder"
        last_response.body.should include "<verbatim>Latrodectus hasselti</verbatim>"
      end
  
      it "should follow 302 status code" do
        get "/find?input=#{TEST}&type=url&format=xml&client=taxonfinder"
        last_response.body.should include "<verbatim>Ursus maritimus</verbatim>"
      end

      it "should return 400 if the status code is not 200, 301 or 302" do
        get "/find?input=#{TEST}&type=url&format=xml&client=taxonfinder"
        last_response.status.should eq 200
      end
      
      it "Should return 400 if the status code is 418" do
        get "/find?input=#{TEST}&type=url&format=xml&client=taxonfinder"
        last_response.status.should eq 400
      end
      it "Should return 400 if the status code is 999" do
        get "/find?input=#{TEST}&type=url&format=xml&client=taxonfinder"
        last_response.status.should eq 400
      end
      it "Should return 400 if the status code is 500" do
        get "/find?input=#{TEST}&type=url&format=xml&client=taxonfinder"
        last_response.status.should eq 400
      end
      
    end
    
    describe 'Error Pages' do
      describe 'From API' do
        it 'should halt 500 and send an exception notification' do
          
          # All we're doing here is making sure some piece of our code raises an Exception
          @neti_mock = double('netineticlient')
          NetiNetiClient.stub(:new).and_raise(Exception)
          
          get "/find?input=some_text&type=text&format=json&client=neti"
          last_response.status.should eq 500
        end
      end
    end

    describe "HTML UI" do
      before(:each) do
        @neti_mock = double('netineticlient')
        NetiNetiClient.stub(:new).and_return(@neti_mock)
        FakeWeb.clean_registry
      end
      it "should normalize a user-entered URL" do
        FakeWeb.register_uri(:get, 'http://www.google.com', :body => "the Googles", :content_type => 'text/html')
        
        @neti_mock.should_receive(:find).with("the Googles", true)
      
        post '/find?url=http://www.google.com&example_url=&freetext=&client=neti&from_web_form=Submit'
      end
    
      it "should normalize an example URL" do
        FakeWeb.register_uri(:get, 'http://species.asu.edu/2010_species10', :body => "2010 New Species OMG", :content_type => 'text/html')
        @neti_mock.should_receive(:find).with('2010 New Species OMG', true)
      
        post '/find?url=&example_url=http://species.asu.edu/2010_species10&freetext=&client=neti&from_web_form=Submit'
      end
    
      it "should normalize free text" do
        @neti_mock.should_receive(:find).with('Dood free text is so mad syq', true)
      
        post '/find?url=&example_url=&freetext=Dood+free+text+is+so+mad+syq&client=neti&from_web_form=Submit'
      end
    
      it "should handle both GETs and POSTs" do
        @neti_mock.should_receive(:find).with('Dood free text is so mad syq', true).twice()

        get '/find?url=&example_url=&freetext=Dood+free+text+is+so+mad+syq&client=neti&from_web_form=Submit'
        post '/find?url=&example_url=&freetext=Dood+free+text+is+so+mad+syq&client=neti&from_web_form=Submit'
      end
    end
    
    describe 'helper methods' do
      describe 'to_json(names)' do
        before do
          @names = [Name.new('Drosophila melanogaster', :start_position => 2345),
                   Name.new('Homo sapiens', :start_position => 3333),
                   Name.new('Mus musculus', :start_position => 4929)]
        end
        it "should take a list of names" do
          lambda {json = to_json @names}.should_not raise_exception
        end
        it "should return proper json" do 
          json = JSON.parse(to_json(@names))
          json['names'].each_with_index do |name, i|
            name['verbatim'].should eq @names[i].verbatim
            name['offsetStart'].should eq @names[i].start_pos
            name['offsetEnd'].should eq @names[i].end_pos
          end
        end
      end
    end
    
    describe 'time(&block)' do
      it "should take a block and return a time" do
        return_time = time { sleep 0.01 }
        return_time.should be_within(0.001).of(0.01)
      end
    end
    
    describe 'client_factory(client_name)' do
      it "should give a NetiNetiClient if passed 'neti'" do
        client_factory('neti').should be_an_instance_of NetiNetiClient
      end

      it "should default to TaxonFinderClient otherwise" do
        client_factory('taxonfinder').should be_an_instance_of TaxonFinderClient
        client_factory('snapple').should be_an_instance_of TaxonFinderClient
        client_factory('').should be_an_instance_of TaxonFinderClient
        client_factory(nil).should be_an_instance_of TaxonFinderClient
      end
    end
    
    describe 'coerce(text)' do
      it "should unescape text" do
        coerce("%41%42%43%44%45%46%47%48%49%4A%4B%4C%4D%4E%4F").should eq 'ABCDEFGHIJKLMNO'
        coerce("%50%51%52%53%54%55%56%57%58%59%5A").should eq 'PQRSTUVWXYZ'
        coerce("%61%62%63%64%65%66%67%68%69%6A%6B%6C%6D%6E%6F").should eq 'abcdefghijklmno'
        coerce("%70%71%72%73%74%75%76%77%78%79%7A").should eq 'pqrstuvwxyz'
      end
      
      it "should convert all strings to utf-8 even if it has to delete characters in it" do
        # this is basically impossible in ruby 1.8.7. If we ever switch to 1.9.x we can implement this.
      end
      
      it "should remove certain characters and replace them with spaces. < > / \t : =" do
         text = "this>text<will/have\tspaces:and=stuff"
         coerce(text).should eq "this text will have spaces and stuff"
      end
    end
    
    
  end
  
  