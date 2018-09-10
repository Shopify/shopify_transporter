# frozen_string_literal: true

module ShopifyTransporter
  module Exporters
    class ExportError < StandardError; end

    class InvalidConfigError < ExportError
      def initialize(error_message)
        super("Invalid configuration: #{error_message}")
      end
    end

    class Exporter
      def initialize(config_filename, object_type)
        @object_type = object_type

        load_config(config_filename)
      end

      def run
        client = Magento::Soap.new(
          config['export_configuration']['soap']['hostname'],
          config['export_configuration']['soap']['username'],
          config['export_configuration']['soap']['api_key'],
        )
        store_id = config['export_configuration']['store_id']

        data = Magento::MagentoExporter.for(type: object_type, store_id: store_id, client: client).export

        puts JSON.pretty_generate(data) + $INPUT_RECORD_SEPARATOR
      end

      private

      attr_reader :config, :object_type

      def load_config(config_filename)
        @config ||= begin
          raise InvalidConfigError, "cannot find file name '#{config_filename}'" unless File.exist?(config_filename)
          YAML.load_file(config_filename)
        end
        ensure_config_has_required_keys
      end

      def ensure_config_has_required_keys
        [
          %w(export_configuration),
          %w(export_configuration soap hostname),
          %w(export_configuration soap username),
          %w(export_configuration soap api_key),
          %w(export_configuration store_id),
        ].each do |keys|
          raise InvalidConfigError, "missing required key '#{keys.last}'" unless config.dig(*keys)
        end
      end
    end
  end
end
