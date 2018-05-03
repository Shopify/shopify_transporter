# frozen_string_literal: true
require_relative 'pipeline/stage.rb'
Dir["#{File.dirname(__FILE__)}/pipeline/all_platforms/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/pipeline/magento/**/*.rb"].each { |f| require f }
