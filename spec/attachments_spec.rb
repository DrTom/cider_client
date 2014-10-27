require 'rspec'
require 'webmock'
require 'webmock/rspec'
require 'pry'

require 'cider_client'

def response_file(path)
  File.open(File.expand_path("responses/#{path}", File.dirname(__FILE__)))
end

describe 'CiderClient' do

  before(:all) do
    # Yes, it's for the V1 API, folks!
    base_url = 'user:pass@cider.example.org/cider-ci/api/v1'
    stub_request(:get,
                 "#{base_url}/execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6").
      to_return(:body => response_file('execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/index.json'),
                :status => 200,
                :headers => { 'Content-type' => 'application/json' })

    stub_request(:get,
                 "#{base_url}/execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks").
      to_return(:body => response_file('execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks/index.json'),
                :status => 200,
                :headers => { 'Content-type' => 'application/json' })

    stub_request(:get,
                 "#{base_url}/execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks").
      with(:query => {:page => 1}).
      to_return(:body => response_file('execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks/page_1.json'),
                :status => 200,
                :headers => { 'Content-type' => 'application/json' })

    @cc = CiderClient.new
    @cc.username = 'user'
    @cc.password = 'pass'
    @cc.host = 'cider.example.org'
  end

  it 'should list some tasks' do
    @cc.execution_id = 'f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6'
    # TODO: Many many mocks
    #@cc.tasks

  end

end
