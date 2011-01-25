require 'rubygems'
ENV["RAILS_ENV"] ||= 'test'
require 'rspec'
#require 'logger'

#Encoding.default_external = 'ascii' if defined? Encoding
#ASSET_ROOT = File.expand_path(File.dirname(__FILE__))

require File.expand_path("../../lib/jammit-s3", __FILE__)

RSpec.configure do |config|
  config.mock_with :rspec

  # run only groups with :focus => true
  # http://relishapp.com/rspec/rspec-core/v/2-4/dir/filtering/run-all-when-everything-filtered
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
