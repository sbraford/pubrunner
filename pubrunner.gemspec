# -*- encoding: utf-8 -*-
require File.expand_path('../lib/pubrunner/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Shanti Braford"]
  gem.email         = ["shantibraford@gmail.com"]
  gem.description   = %q{Do publishing androids dream of electric sheep? We think so.}
  gem.summary       = %q{A gem for novelists. Automate common tasks around the publication and distribution of novels.}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "pubrunner"
  gem.require_paths = ["lib"]
  gem.version       = Pubrunner::VERSION
end
