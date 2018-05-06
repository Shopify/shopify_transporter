# frozen_string_literal: true
ruby '2.4.0'

source "https://rubygems.org"

# Specify your gem's dependencies in shopify_transporter.gemspec
gemspec

group :development do
  gem 'package_cloud'
  gem 'rubocop'
  gem 'rubocop-git', '~> 0.1'
end

group :test do
  gem 'codecov', require: false
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'factory_bot', '~> 4.8'
  gem 'pry', '~> 0.11'
  gem 'pry-byebug'
  gem 'rspec', '~> 3.0'
end