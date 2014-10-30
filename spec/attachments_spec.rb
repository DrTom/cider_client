require 'rspec'
require 'pry'
require 'webmock_smartloader'
require 'webmock_api_version'

require 'cider_client'

describe 'CiderClient' do

  before(:each) do
    load_stubs
    load_attachments
    mock_api_version('v1', 404)
    mock_api_version('v2', 200)
    @cc ||= CiderClient.new(:host => 'cider.example.org', :username => 'user', :password => 'pass')
    @cc.execution_id = '2e9f69c5-e19c-4d9d-8793-714edbc7edb5'
  end

  it 'should list the tasks of an execution' do
    expect(@cc.tasks.count).to eq(3)
  end

  it 'should list the correct number of trial_attachment_hrefs' do
    expect(@cc.trial_attachment_hrefs.count).to eq(6)
  end

  # rubocop:disable Metrics/LineLength
  it 'should filter trial_attachment_hrefs by attachment name using a regex' do
    logs = @cc.trial_attachment_hrefs(/test\.log/)
    expect(logs).to eq(['/cider-ci/api/v2/trial-attachment/e563f6c7-2c0a-4af8-ab63-0b4a9b7c8139/log/test.log',
                        '/cider-ci/api/v2/trial-attachment/14d441c4-f709-4a32-890e-3383e9c13025/log/test.log'])

    resultsets = @cc.trial_attachment_hrefs(/\.resultset\.json$/)
    expect(resultsets).to eq(['/cider-ci/api/v2/trial-attachment/e563f6c7-2c0a-4af8-ab63-0b4a9b7c8139/coverage/.resultset.json',
                              '/cider-ci/api/v2/trial-attachment/14d441c4-f709-4a32-890e-3383e9c13025/coverage/.resultset.json'])
  end

  it 'should retrieve attachment data from the location Cider indicates' do
    resultsets = @cc.trial_attachment_hrefs(/\.resultset\.json$/)
    # If it's this big, it can't just be an error message or something
    expect(@cc.attachment_data(resultsets[1]).size).to eq(102628)
    # TODO: Check the actual content of the file
  end

end
