require 'uri'
require 'open-uri'
require 'fileutils'

require 'rubygems'
require 'bundler/setup'

require 'builder'
require 'json'
require 'nokogiri'
require 'sinatra'
require 'sinatra/content_for'
require 'haml'
require 'fakeweb'
require 'pony'

# This is not 1.9 compatible. #
require 'iconv'

require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'taxon_finder_client'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'netineti_client'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lib', 'monkey_patches'))

Rack::Mime::MIME_TYPES[".woff"] = 'text/plain'
Rack::Mime::MIME_TYPES[".ttf"] = 'text/plain'

# Example URLs are cached to disk.
# We tried to use settings.root here but couldn't make it work.
# FakeWeb.register_uri(:get, 'http://www.sciencedaily.com/news/plants_animals/new_species/', :body => "#{File.dirname(__FILE__)}/example_urls/science_daily_new_species.html", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://www.livescience.com/environment/top-10-new-species-1.html', :body => "#{File.dirname(__FILE__)}/example_urls/top-10-new-species-1.html", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://www.sciencedaily.com/releases/2010/04/100407104032.htm', :body => "#{File.dirname(__FILE__)}/example_urls/100407104032.htm", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://ia311319.us.archive.org/3/items/americanseashell00abbo/americanseashell00abbo_djvu.txt', :body => "#{File.dirname(__FILE__)}/example_urls/americanseashell00abbo_djvu.txt", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://ia341016.us.archive.org/3/items/britishinsectsge00westuoft/britishinsectsge00westuoft_djvu.txt', :body => "#{File.dirname(__FILE__)}/example_urls/britishinsectsge00westuoft_djvu.txt", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://ia340912.us.archive.org/3/items/handbookofzoolog01hoevrich/handbookofzoolog01hoevrich_djvu.txt', :body => "#{File.dirname(__FILE__)}/example_urls/handbookofzoolog01hoevrich_djvu.txt", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://species.asu.edu/2009_species05', :body => "#{File.dirname(__FILE__)}/example_urls/2009_species05", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://species.asu.edu/2009_species10', :body => "#{File.dirname(__FILE__)}/example_urls/2009_species10", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://species.asu.edu/2009_species09', :body => "#{File.dirname(__FILE__)}/example_urls/2009_species09", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://species.asu.edu/2009_species08', :body => "#{File.dirname(__FILE__)}/example_urls/2009_species08", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://species.asu.edu/2009_species06', :body => "#{File.dirname(__FILE__)}/example_urls/2009_species06", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://species.asu.edu/2009_species05', :body => "#{File.dirname(__FILE__)}/example_urls/2009_species05", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://species.asu.edu/2010_species05', :body => "#{File.dirname(__FILE__)}/example_urls/2010_species05", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://species.asu.edu/2010_species09', :body => "#{File.dirname(__FILE__)}/example_urls/2010_species09", :content_type => 'text/html')
FakeWeb.register_uri(:get, 'http://species.asu.edu/2010_species10', :body => "#{File.dirname(__FILE__)}/example_urls/2010_species10", :content_type => 'text/html')

helpers do
  def dedup(name_objects)
    return "" if name_objects.nil?
    name_strings = Array.new
    new_names = Array.new
    name_objects.each do |name|
      unless name_strings.include? name.verbatim
        new_names << name
        name_strings << name.verbatim
      end
    end
    new_names
  end
  
  def number_with_delimiter(number)
    begin
      Float(number)
    rescue ArgumentError, TypeError
      if options[:raise]
        raise InvalidNumberError, number
      else
        return number
      end
    end

    parts = number.to_s.split('.')
    parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1,")
    parts.join('.')
  end
  
  def image_link(image, link, options={})
    haml_tag :a, :href => link do
      haml_tag :img, {:src => "/images/#{image}"}.merge(options)
    end
  end
  
  def awesome_truncate(text, length = 30, truncate_string = "...")
    return if text.nil?
    l = length - truncate_string.chars.to_a.length
    text.chars.to_a.length > length ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
  end
end

error 400 do
  error_page 400, 'Invalid URL', "The URL you have entered does not point to a valid web page. Please doublecheck it and try again."
end

error 415 do
  error_page 415, 'Unsupported File Type', "Namefinding is currently supported only in plain text documents. Right now, PDF and Microsoft Word documents are not supported. If these document formats are important to you, please <a href='/contact' title='Contact Form'>let us know</a>."
end

error 404 do
  error_page 404, 'Page Not Found', 'The requested URL could not be found on this server'
end

error Exception do
  configure :production do
    unless request.env['sinatra.error'].message.include? 'Unknown media type' # Fuck sinatra/respond_to times a million
      Pony.mail(:to => 'rschenk@mbl.edu, cha@mbl.edu', :from => "'Namefinding Error' <namefinding_error@mbl.edu>", :subject => 'Namefinding Error' , 
                :body => erb(:exception_notification, :layout => false, :locals => {:error => request.env['sinatra.error'], :params => params, :path => request.env['REQUEST_URI']}) ) 
    end
  end
  error_page
end


def error_page(status_code=500, title=nil, message=nil)
  if from_web_form?
    status status_code
    haml :exception, :locals => { :title => title, :message => message}
  else
    halt status_code
  end
end

get '/' do
  haml :finder_form
end

post '/find' do
  find_names 
end

get '/find' do
  find_names
end

get '/api-docs' do
  haml 'api-documentation'.to_sym
end

get '/contact' do
  haml :contact
end

post '/contact' do
  Pony.mail(:to => 'hmiller@mbl.edu', :from => "'#{params[:name]}' <#{params[:email]}>", :subject => 'Namefinding Tools Feedback', :body => params[:message])
  haml :contact_thanks
end

def find_names
  input, type = from_web_form? ? parse_web_form_request : parse_api_request
  client = client_factory params[:client]
  input = "" if input.nil?
  case type
  when 'url' then input = download_url(input)
  when 'file' then input = read_uploaded_file(input)
  end
  
  
  input = coerce input
  finding_time = time{ @names = client.find(input, from_web_form?) }
  
  if from_web_form?
    @names = dedup @names
    haml :results, :locals => {:names => @names, :finding_time => finding_time}
  elsif params[:format] and params[:format].downcase == 'json'
    content_type :json
    to_json @names
  else
    content_type :xml, :charset => 'utf-8'
    builder :results
  end
end

# The parameters that the webservice exposes in its API are incompatible with the way web forms work.
# So, the params that + in from the HTML form will be totally different than what is expected.
# This little function tests the params to see if they came in from the HTML form, and if so map
# them into the parameters that we're expecting
#
# It reads the parameters in the reverse order that they appear in the form. The idea being that a 
# user will fill out the form from top to bottom. Therefore, the most recent information entered
# would be on the bottom of the form. This isn't perfect, but I think it's the best assumption.
def parse_web_form_request
  if !params[:file].blank?
    return [params[:file], 'file']
  elsif !params[:freetext].blank?
    return [params[:freetext], 'text']
  elsif !params[:url].blank?
    return [params[:url], 'url']
  elsif !params[:example_url].blank?
    return [params[:example_url], 'url']
  end  
end

def parse_api_request
  [params[:input], params[:type] || 'text']
end

def download_url(url)
  begin
    response = open(url.to_s)
    check_mime_type(response.content_type) # raise an exception if not text or xml 
    body = response.read
    body
  rescue 
    halt 400
  end
end

def coerce(text)
  text = URI.unescape text
  ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
  text = ic.iconv(text + ' ')[0..-2]
  text.gsub(/[\<|\>|\/|\t|\:|\=]/, ' ')
end

def read_uploaded_file(input)
  check_mime_type input[:type]
  input[:tempfile].read
end

def check_mime_type(mime_type)
  if from_web_form?
    unless mime_type.include?('text') || mime_type.include?('xml')
      halt 415
    end
  end
end

# Defaults to TaxonFinder
def client_factory(client_name)
  case client_name
  when 'neti' then NetiNetiClient.new
  else TaxonFinderClient.new
  end
end

def from_web_form?
  !params[:from_web_form].blank?
end

def to_json(names)
  jsonnames = []
  names.each do |name|
    name_hash = {"verbatim" => name.verbatim}
    name_hash['scientificName'] = name.scientific if name.scientific
    name_hash['offsetStart'] = name.start_pos if name.start_pos
    name_hash['offsetEnd'] = name.end_pos if name.end_pos
    jsonnames << name_hash 
  end
  return JSON.fast_generate({"names" => jsonnames})
end


def time(&block)
  t1 = Time.now
  yield
  Time.now - t1
end

