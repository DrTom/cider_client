require 'cider_client'
require 'webmock_api_version'

describe 'CiderClient' do

  it 'should construct a decent execution URL' do
    mock_api_version('v2', 200, {:username => 'foober', :password => 'the_fooinator'})
    cc = CiderClient.new(:host => 'cider.example.org',
                         :username => 'foober',
                         :password => 'the_fooinator')
    expect(cc.base_url).to eq('http://foober:the_fooinator@cider.example.org')
  end

  it 'should refuse to work with the wrong API version on the server' do
    mock_api_version('v1', 200, { :username => 'user', :password => 'pass'} )
    mock_api_version('v2', 404, { :username => 'user', :password => 'pass'})
    expect {
      cc = CiderClient.new(:host => 'cider.example.org',
                           :username => 'user',
                           :password => 'pass')
    }.to raise_error
  end

end
