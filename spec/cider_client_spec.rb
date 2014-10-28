require 'cider_client'

describe 'CiderClient' do

  it 'should construct a decent execution URL' do
    cc = CiderClient.new
    cc.username = 'foober'
    cc.password = 'the_fooinator'
    cc.host = 'cider.example.org'
    expect(cc.base_url).to eq('http://foober:the_fooinator@cider.example.org')
  end

end
