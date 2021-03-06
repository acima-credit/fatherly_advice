# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fatherly_advice/version'

Gem::Specification.new do |spec|
  spec.name          = 'fatherly_advice'
  spec.version       = FatherlyAdvice::VERSION
  spec.authors       = ['Adrian Esteban Madrid']
  spec.email         = ['aemadrid@gmail.com']

  spec.summary       = 'Utility belt for Funding Fathers common patterns.'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/acima-credit/fatherly_advice'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'actionpack'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'excon'
  spec.add_dependency 'jwt'
  spec.add_dependency 'redis'

  spec.add_development_dependency 'activerecord'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-performance'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'timecop'
end
