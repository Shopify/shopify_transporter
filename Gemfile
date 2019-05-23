# frozen_string_literal: true
source "https://rubygems.org"

# Specify your gem's dependencies in shopify_transporter.gemspec
gemspec

group :development do
  gem 'package_cloud'
  gem 'rubocop'
  gem 'rubocop-git'
end

group :test do
  gem 'codecov', require: false
  gem 'simplecov', require: false
end

group :development, :test do
  gem 'factory_bot'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rspec'
end
