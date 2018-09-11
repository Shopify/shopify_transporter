# frozen_string_literal: true
require_relative './base_group.rb'

module ShopifyTransporter
  class Generate < BaseGroup
    class_option :object, type: :string, required: :true,
      enum: %w(customer order), aliases: '-O',
      desc: 'The object to add to the pipeline stage'

    def object_type
      @object_type ||= options[:object].capitalize
    end

    def validate_config_exists
      unless File.exist?(config_filename)
        say('Cannot find config.yml at project root', :red)
        exit 1
      end
    end

    def pipeline_snake_name
      name_components.map(&:underscore).join('_')
    end

    def pipeline_class
      @pipeline_class ||= @name_components.map(&:classify).join('')
    end

    def platform
      platform_type = YAML.load_file(config_filename)['platform_type']
      @platform_file_path ||= SUPPORTED_PLATFORMS_MAPPING[platform_type]
      @platform ||= platform_type.underscore
    end

    def generate_stage
      template(
        'templates/custom_stage.tt',
        "lib/custom_pipeline_stages/#{pipeline_snake_name}.rb"
      )
    end

    def add_stage_to_config
      config_file = YAML.load_file(config_filename)
      unless class_included_in?(config_file)
        pipeline_class_hash = { @pipeline_class.to_s => nil, 'type' => 'custom' }
        config_file['object_types'][@object_type.downcase]['pipeline_stages'] << pipeline_class_hash
        File.open(config_filename, 'w') { |f| f.write config_file.to_yaml }
        say('Updated config.yml with the new pipeline stage', :green)
        return
      end

      say("Warning: The pipeline stage #{@pipeline_class} already exists in the config.yml", :blue)
    end

    private

    def class_included_in?(config_file)
      hash_stages = config_file['object_types'][@object_type.downcase]['pipeline_stages'].select do |stage|
        stage.is_a? Hash
      end
      hash_stages.find { |h| h.keys.include? @pipeline_class.to_s }.present?
    end
  end
end
