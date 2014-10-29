require 'webmock'
require 'webmock/rspec'
require 'json'

ROOT_URL = 'user:pass@cider.example.org'

def self_href_from_file(path)
  parsed = JSON.parse(File.read(path))
  if parsed['_links']
    parsed['_links']['self']['href']
  else
    parsed[0]['_links']['self']['href']
  end
end

def mock_index(path)
  self_url = "#{ROOT_URL}#{self_href_from_file(path)}"
  stub_request(:get,
               self_url).
   to_return(:body => path,
            :status => 200,
            :headers => { 'Content-type' => 'application/json' })
end

def mock_page(path, page_number)
  self_url = "#{ROOT_URL}#{self_href_from_file(path)}"
  stub_request(:get,
               self_url).
   with(:query => {:page => page_number}).
   to_return(:body => path,
            :status => 200,
            :headers => { 'Content-type' => 'application/json' })
end

def load_stubs
    mocks_dir = File.expand_path("responses", File.dirname(__FILE__))
    Dir.glob(File.join(mocks_dir, "**", "*.json")) do |path|
      if File.basename(path) =~ /^page/
        page_number = File.basename(path).match(/^page\_(\d)\.json/)[1]
        mock_page(path, page_number)
      else
        mock_index(path)
      end
    end
end
