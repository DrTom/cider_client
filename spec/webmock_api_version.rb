# encoding: utf-8
require 'webmock'
require 'webmock/rspec'

def mock_api_version(version, status, options = {:username => 'user', :password => 'pass'})
  auth = "#{options[:username]}:#{options[:password]}@"
  stub_request(:get,
               "#{auth}cider.example.org/cider-ci/api/#{version}/").
    to_return(:body => "Iä, iä! Shubb-Niggurath!",
              :status => status,
              :headers => { 'Content-type' => 'text/html' })
end
