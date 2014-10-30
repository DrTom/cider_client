require 'webmock'
require 'webmock/rspec'
require 'json'

ROOT_URL = 'user:pass@cider.example.org'

def self_href_from_file(path)
  parsed = JSON.parse(File.read(path))
  parsed['_links']['self']['href']
end

def mock_index(path)
  self_url = "#{ROOT_URL}#{self_href_from_file(path)}"
  #puts "Stubbing: #{self_url} with #{path}"
  stub_request(:get, self_url).
    to_return(:body => File.read(path),
              :status => 200,
              :headers => { 'Content-type' => 'application/json' })
end

def mock_page(path, page_number)
  self_url = "#{ROOT_URL}#{self_href_from_file(path)}"
  #puts "Stubbing: #{self_url}, page #{page_number} with #{path}"
  stub_request(:get, self_url).
   with(:query => {:page => page_number}).
   to_return(:body => File.read(path),
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

def load_attachments
  files = [
            { :url => 'storage/trial-attachments/14d441c4-f709-4a32-890e-3383e9c13025/coverage/.last_run.json',
              :path => 'storage_trial-attachments_14d441c4-f709-4a32-890e-3383e9c13025_coverage_.last_run.json',
              :content_type => 'application/json' },

            { :url => 'storage/trial-attachments/14d441c4-f709-4a32-890e-3383e9c13025/coverage/.resultset.json',
              :path => 'storage_trial-attachments_14d441c4-f709-4a32-890e-3383e9c13025_coverage_.resultset.json',
              :content_type => 'application/json' }
          ]

  files.each do |file|
    url = "http://ci1.zhdk.ch:80/cider-ci/#{file[:url]}"
    path = File.join(File.expand_path("data", File.dirname(__FILE__)), file[:path])
    stub_request(:get, url).
      to_return(:body => File.read(path),
                :status => 200,
                :headers => { 'Content-type' => file[:content_type] })
  end

end
