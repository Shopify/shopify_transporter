# frozen_string_literal: true

module ShopifyTransporter
  class ExportError < StandardError; end

  class OutputFileExistsError < ExportError
    def initialize(output_filename)
      super("Output filename already exists: '#{output_filename}'")
    end
  end

  class InvalidConfigError < ExportError
    def initialize(error_message)
      super("Invalid configuration: #{error_message}")
    end
  end

  class Exporter
    def initialize(config_filename, api_key, object_type, output_filename)
      @api_key = api_key
      @output_filename = output_filename
      @object_type = object_type

      load_config(config_filename)

      ensure_config_has_required_keys
      ensure_output_file_does_not_exist
    end

    def run
      client = Soap.new(
        @config['export_configuration']['soap']['hostname'],
        @config['export_configuration']['soap']['username'],
        api_key,
      )
      store_id = @config['export_configuration']['store_id']

      data = MagentoExporter.for(store_id, object_type, client).export

      File.open(output_filename, 'w') do |output_file|
        output_file.write(JSON.pretty_generate(data), $/)
      end
    end

    private

    attr_reader :config, :api_key, :output_filename, :object_type

    def load_config(config_filename)
      @config ||= begin
        raise InvalidConfigError, "cannot find file name '#{config_filename}'" unless File.exists?(config_filename)
        YAML.load_file(config_filename)
      end
    end

    def ensure_config_has_required_keys
      [
        ['export_configuration'],
        ['export_configuration', 'soap', 'hostname'],
        ['export_configuration', 'soap', 'username'],
        ['export_configuration', 'store_id'],
      ].each do |keys|
        raise InvalidConfigError, "missing required key '#{keys.last}'" unless config.dig(*keys)
      end
    end

    def ensure_output_file_does_not_exist
      raise OutputFileExistsError, output_filename if File.exists?(output_filename)
    end
  end
end
