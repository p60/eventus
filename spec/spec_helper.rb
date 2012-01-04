require 'rubygems'
require 'bundler/setup'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'eventus'

Bundler.require :development

Dir[File.join(File.dirname(__FILE__), 'support', '*.rb')].each { |d| require d }

RSpec.configure do |config|
  config.mock_with :rspec
end
