# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record_lite/version'

Gem::Specification.new do |spec|
  spec.name          = "active_record_lite"
  spec.version       = ActiveRecordLite::VERSION
  spec.authors       = ["Isaac Murchie"]
  spec.email         = ["imurchie@gmail.com"]
  spec.description   = %q{ActiveRecordLite: A basic version of Rails' ActiveRecord functionality}
  spec.summary       = %q{Basic ORM}
  spec.homepage      = "http://imurchie.github.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency "activesupport"
  spec.add_runtime_dependency "sqlite3"
end
