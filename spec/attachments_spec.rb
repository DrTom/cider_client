require 'rspec'
require 'pry'
require 'webmock_smartloader'
require 'webmock_api_version'

require 'cider_client'

describe 'CiderClient' do

  before(:each) do
    load_stubs
    load_attachments
    mock_api_version("v1", 404)
    mock_api_version("v2", 200)
    @cc ||= CiderClient.new(:host => 'cider.example.org', :username => 'user', :password => 'pass')
    @cc.execution_id = '2e9f69c5-e19c-4d9d-8793-714edbc7edb5'
  end

  it 'should list the tasks of an execution' do
    expect(@cc.tasks.count).to eq(3)
  end

  it 'should list the correct number of trial_attachment_hrefs' do
    expect(@cc.trial_attachment_hrefs.count).to eq(6)
  end

end
