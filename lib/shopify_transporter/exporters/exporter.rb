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
        data = Magento::MagentoExporter.for(
          type: object_type,
          store_id: config['export_configuration']['store_id'],
          soap_client: soap_client,
          database_adapter: database_adapter
        ).export

        puts JSON.pretty_generate(data) + $INPUT_RECORD_SEPARATOR
      end

      private

      attr_reader :config, :object_type

      def soap_client
        soap_client = Magento::Soap.new(
          hostname: config['export_configuration']['soap']['hostname'],
          username: config['export_configuration']['soap']['username'],
          api_key: config['export_configuration']['soap']['api_key'],
        )
      end

      def database_adapter
        database_adapter = Magento::SQL.new(
          database: config['export_configuration']['database']['name'],
          hostname: config['export_configuration']['database']['hostname'],
          username: config['export_configuration']['database']['username'],
          port: config['export_configuration']['database']['port'],
          password: config['export_configuration']['database']['password'],
        )
      end

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
