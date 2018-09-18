# frozen_string_literal: true
$:.push File.expand_path('../lib', __FILE__)
require 'shopify_transporter/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 2.4.0'

  spec.name          = %q{shopify_transporter}
  spec.version       = ShopifyTransporter::VERSION
  spec.author       = 'Shopify'
  spec.email         = %q{developers@shopify.com}

  spec.summary       = 'Tools for migrating to Shopify'
  spec.description   = 'The Transporter tool allows you to convert data from a third-party platform into a format that can be imported into Shopify.'
  spec.homepage      = %q{https://help.shopify.com/manual/migrating-to-shopify}
  spec.license       = 'Shopify'
  spec.extra_rdoc_files = [
    'LICENSE',
    'README.md',
    'RELEASING'
  ]

  whitelisted_files = "exe lib Gemfile LICENSE Rakefile README.md shopify_transporter.gemspec"

  spec.files = `git ls-files -z #{whitelisted_files}`.split("\x0")
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1'
  spec.add_development_dependency 'rake', '~> 12.3'

  spec.add_dependency 'savon'
  spec.add_dependency 'json'
  spec.add_dependency 'activesupport', '~> 5.1'
  spec.add_dependency 'thor', '~> 0.20'
  spec.add_dependency 'yajl-ruby', '~> 1.3'
end
