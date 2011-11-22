Gem::Specification.new do |s|
  s.name        = 'gem2pkg'
  s.version     = '0.1.2'
  s.date        = '2011-11-21'
  s.summary     = "OSX packages from Ruby Gems!"
  s.description = "Creates Mac OSX installer packages for 10.5 and up from ruby gems"
  s.authors     = ["Justin Schumacher"]
  s.email       = 'justin@thethinkingtree.com'
  s.executables << 'gem2pkg'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'http://rubygems.org/gems/gem2pkg'
  s.required_rubygems_version = ">= 1.3.6"
  s.require_paths      = ["lib"]
end