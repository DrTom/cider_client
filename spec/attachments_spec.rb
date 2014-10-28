require 'rspec'
require 'pry'
require 'webmock_utils'

require 'cider_client'

describe 'CiderClient' do

  before(:each) do
    basic_stubs
    @cc ||= CiderClient.new
    @cc.username = 'user'
    @cc.password = 'pass'
    @cc.host = 'cider.example.org'
  end

  it 'should list the tasks of an execution' do
    @cc.execution_id = 'f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6'
    expect(@cc.tasks.count).to eq(6)
  end

  it 'should list the correct number of trial_attachment_hrefs' do
    @cc.execution_id = 'f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6'
    expect(@cc.trial_attachment_hrefs.count).to eq(6)
  end

end
