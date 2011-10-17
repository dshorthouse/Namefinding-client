require File.expand_path(File.join(File.dirname(__FILE__), '..','taxon_finder_web_service'))

require 'rubygems'
require 'rspec'
require 'rack/test'
require 'fakeweb'

FakeWeb.allow_net_connect = %r[^https?://localhost]

set :environment, :test

RSpec.configure do |config|
  config.mock_with :rspec
end