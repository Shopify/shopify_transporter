# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter %r{^/spec/}
end
SimpleCov.refuse_coverage_drop
SimpleCov.minimum_coverage 98.6

if ENV['CI']
  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
end
