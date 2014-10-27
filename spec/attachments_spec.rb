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

    stub_request(:get,
                 "#{base_url}/execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks").
      with(:query => {:page => 2}).
      to_return(:body => response_file('execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks/page_2.json'),
                :status => 200,
                :headers => { 'Content-type' => 'application/json' })


    tasks = ['08abffb3-ee8e-403b-949a-0e95e6a78ac0', '4c0d5916-2e2a-4caf-aa79-b6df54652614',
             '5892453f-8555-4c1b-894c-e1cb70891f1c', 'ce4bd431-e193-4333-a0d5-61332fe3ed5d']

    tasks.each do |task|
    stub_request(:get,
                 "#{base_url}/task/#{task}").
      to_return(:body => response_file("task/#{task}.json"),
                :status => 200,
                :headers => { 'Content-type' => 'application/json' })
    end

    @cc = CiderClient.new
    @cc.username = 'user'
    @cc.password = 'pass'
    @cc.host = 'cider.example.org'
  end

  it 'should list some tasks' do
    @cc.execution_id = 'f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6'
    @cc.tasks
  end

end
