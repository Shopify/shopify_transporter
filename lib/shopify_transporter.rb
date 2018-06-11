# frozen_string_literal: true
require 'thor'

require_relative 'shopify_transporter/generators.rb'
require_relative 'shopify_transporter/exporter.rb'
require_relative 'shopify_transporter/pipeline.rb'
require_relative 'shopify_transporter/shopify.rb'
require_relative 'shopify_transporter/record_builder.rb'

Dir["#{Dir.pwd}/lib/custom_pipeline_stages/**/*.rb"].each { |f| require f }

module ShopifyTransporter
  DEFAULT_METAFIELD_NAMESPACE = 'migrated_data'
end

require 'csv'
require 'yaml'
require 'yajl'

class TransporterTool
  class ConversionError < StandardError; end

  class StageNotFoundError < ConversionError
    def initialize(stage_name)
      super("Unable to find stage named '#{stage_name}'")
    end
  end

  class InvalidObjectType < ConversionError
    def initialize(object_type)
      super(
        "Unable to find object type named: '#{object_type}' in config.yml." \
        "Are you sure '#{object_type}' is listed in the config.yml?"
            )
    end
  end

  class UnsupportedStageTypeError < ConversionError
    def initialize(name, type)
      super(
        "Stage: '#{name}' has an unsupported type: '#{type}'. It must be one of 'default', 'custom' or 'all_platforms'"
      )
    end
  end

  def initialize(*files, config, object_type)
    config_file(config)
    input_files(*files)
    @object_type = object_type
    return if @config.nil? || @input_files.nil?

    raise InvalidObjectType, object_type unless supported_object_type?(object_type)

    build_classes_based_on_config
    initialize_stages
  end

  SUPPORTED_FILE_TYPES = %w(.csv .json)

  def supported_object_type?(object_type)
    @config['object_types'].key?(object_type)
  end

  def initialize_stages
    @pipeline_stages ||= {}
    @config['object_types'][@object_type]['pipeline_stages'].each do |pipeline_stage|
      initialize_pipeline_stage(pipeline_stage)
    end
  end

  def run
    return if @input_files.nil?

    unless file_extension_supported?
      $stderr.puts "File type must be one of: #{SUPPORTED_FILE_TYPES.join(', ')}."
      return
    end

    @input_files.each do |file_name|
      run_based_on_file_ext(file_name)
    end

    complete
  end

  private

  def file_extension_supported?
    @input_files.all? do |file_name|
      ext = get_ext(file_name)
      SUPPORTED_FILE_TYPES.include?(ext)
    end
  end

  def get_ext(file_name)
    File.extname(file_name).downcase
  end

  def run_based_on_file_ext(file_name)
    ext = get_ext(file_name)
    ext == '.csv' ? run_csv(file_name) : run_json(file_name)
  end

  def run_csv(file_name)
    row_number = 1
    CSV.foreach(file_name, headers: true).each do |row|
      row_number += 1
      process(row.to_hash, file_name, row_number)
    end
  end

  def run_json(file_name)
    file_data = File.read(file_name)
    parsed_file_data = Yajl::Parser.parse(file_data)
    return if parsed_file_data.nil? || parsed_file_data.empty?

    record = 1
    parsed_file_data.each do |json_row|
      process(json_row, file_name, record)
      record += 1
    end
  end

  def initialize_pipeline_stage(pipeline_stage)
    name = stage_name(pipeline_stage)
    params = stage_params(pipeline_stage)
    type = stage_type(pipeline_stage)
    @pipeline_stages[name] = stage_class_from(name, type).new(params)
  end

  def stage_name(pipeline_stage)
    pipeline_stage.class == String ? pipeline_stage : pipeline_stage.keys.first
  end

  def class_exists?(pipeline_stage_class)
    pipeline_stage_class && pipeline_stage_class < ShopifyTransporter::Pipeline::Stage
  end

  def stage_params(pipeline_stage)
    pipeline_stage['params'] if pipeline_stage.class == Hash
  end

  def stage_type(pipeline_stage)
    return 'default' if pipeline_stage.class == String || pipeline_stage['type'].nil?
    pipeline_stage['type']
  end

  def custom_stage_class_from(stage_name)
    "CustomPipeline::#{@object_type.capitalize}::#{stage_name}"
  end

  def stage_class_from(name, type)
    class_name = stage_classname(name, type)
    klass = begin
      k = Object.const_get(class_name)
      k.is_a?(Class) && k
    rescue NameError
      nil
    end
    raise StageNotFoundError, name unless class_exists?(klass)
    klass
  end

  def stage_classname(name, type)
    case type
    when 'default'
      "ShopifyTransporter::Pipeline::#{@config['platform_type']}::#{@object_type.capitalize}::#{name}"
    when 'all_platforms'
      "ShopifyTransporter::Pipeline::AllPlatforms::#{name}"
    when 'custom'
      "CustomPipeline::#{@object_type.capitalize}::#{name}"
    else
      raise UnsupportedStageTypeError.new(name, type)
    end
  end

  def process(input, file_name, row_number)
    @record_builder.build(input) do |record|
      run_pipeline(input, record)
    end
  rescue ShopifyTransporter::RequiredKeyMissing, ShopifyTransporter::MissingParentObject => e
    $stderr.puts error_message_from(e, file_name, row_number)
  end

  def run_pipeline(row, record)
    @pipeline_stages.each do |_stage_name, stage|
      stage.convert(row, record)
    end
  end

  def error_message_from(error, file_name, row_number)
    ext = get_ext(file_name)
    if ext == '.csv'
      "error: #{file_name}:#{row_number}, message: #{error.message}"
    else
      "error in file: #{file_name} at record number #{row_number}, message: #{error.message}"
    end
  end

  def complete
    puts @record_class.header
    @record_builder.instances.each do |_, record_hash|
      puts @record_class.new(record_hash).to_csv
    end
  end

  def config_file(config)
    @config = YAML.load_file(config) if valid_config_file?(config)
  end

  def input_files(*files)
    @input_files = *files if valid_files?(*files)
  end

  def valid_config_file?(config)
    valid_file?(config)
  end

  def valid_files?(*files)
    return false if files.any? do |f|
      !valid_file?(f)
    end

    true
  end

  def valid_file?(path)
    unless File.exist?(path)
      puts "File #{path} can't be found"
      return false
    end

    true
  end

  def build_classes_based_on_config
    @record_class = Object.const_get("ShopifyTransporter::Shopify::#{@object_type.capitalize}")
    @record_builder = ShopifyTransporter::RecordBuilder.new(
      record_key_from_config, key_required_from_config
    )
  end

  def record_key_from_config
    @config['object_types'][@object_type]['record_key']
  end

  def key_required_from_config
    @config['object_types'][@object_type]['key_required']
  end
end
