# coding: utf-8
require_relative "lib/mock5/version"

Gem::Specification.new do |spec|
  spec.name                  = "mock5"
  spec.version               = Mock5::VERSION
  spec.authors               = ["Pavel Pravosud"]
  spec.email                 = ["pavel@pravosud.com"]
  spec.summary               = "Mock APIs using Sinatra"
  spec.description           = "Create and manage API mocks with Sinatra"
  spec.homepage              = "https://github.com/rwz/mock5"
  spec.license               = "MIT"
  spec.files                 = `git ls-files -z`.split("\x0")
  spec.test_files            = spec.files.grep(/^spec/)
  spec.require_path          = "lib"
  spec.required_ruby_version = ">= 1.9.3"

  spec.add_dependency "webmock", "~> 1.15"
  spec.add_dependency "sinatra", "~> 1.4"
end
