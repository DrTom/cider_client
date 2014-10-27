Gem::Specification.new do |s|
  s.name        = 'cider_client'
  s.version     = '0.0.1'
  s.licenses    = ['MIT']
  s.summary     = "A client library for the Cider CI API"
  s.description = "Rudimentary library that wraps the Cider CI API in Ruby objects."
  s.authors     = ["Ramón Cahenzli"]
  s.email       = 'rca@psy-q.ch'
  s.files       = ["lib/cider_client.rb"]
  s.add_runtime_dependency 'json', '~> 1.8'
  s.add_runtime_dependency 'rest-client', '~> 1.7'
  s.homepage    = 'https://github.com/psy-q/cider_client'
end
