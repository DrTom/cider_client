require 'rspec'
require 'responses/attachments'
require 'webmock'
require 'webmock/rspec'

describe 'CiderClient' do

  before(:all) do
    stub_request(:any, "cider.example.com")
  end

  it "should do something" do

  end

end
