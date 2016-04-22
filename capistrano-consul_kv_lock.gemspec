# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'capistrano/consul_kv_lock/version'

Gem::Specification.new do |spec|
  spec.name          = "capistrano-consul_kv_lock"
  spec.version       = Capistrano::ConsulKvLock::VERSION
  spec.authors       = ["Uchio KONDO"]
  spec.email         = ["udzura@udzura.jp"]
  spec.summary       = %q{Introduces deployment lock using consul KVS}
  spec.description   = %q{Introduces deployment lock using consul KVS.}
  spec.homepage      = "https://github.com/udzura/capistrano-consul_kv_lock"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "capistrano", ">= 3"
  spec.add_dependency "diplomat"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
end
