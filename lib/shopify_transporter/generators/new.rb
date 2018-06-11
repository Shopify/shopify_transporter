# frozen_string_literal: true
require 'pry'

require_relative './base_group.rb'

module ShopifyTransporter
  class New < BaseGroup
    include Thor::Actions
    class_option :platform, type: :string, required: :true, enum: %w(magento)

    def snake_name
      @snake_name ||= name_components.map(&:downcase).join("_")
    end

    def platform
      @platform ||= options[:platform]
    end

    def generate_config
      template("templates/#{@platform}/config.tt", "#{@snake_name}/config.yml")
      template("templates/gemfile.tt", "#{@snake_name}/Gemfile")
      empty_directory("#{@snake_name}/lib/custom_pipeline_stages")
    end
  end
end
