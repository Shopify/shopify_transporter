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
        print_exported_objects
      end

      private

      attr_reader :config, :object_type

      def print_exported_objects
        $stderr.puts 'Starting export...'
        puts '['
        first = true
        object_exporter.export do |object|
          puts ',' unless first
          first = false
          $stderr.puts "Fetching #{object_type}: #{object[object_exporter.key]}..."
          print '  ' + JSON.pretty_generate(object, object_nl: "\n  ")
        end
      ensure
        print "\n]"
      end

      def object_exporter
        @exporter ||= Magento::MagentoExporter
          .for(type: object_type)
          .new(
            soap_client: soap_client,
            database_adapter: database_adapter
          )
      end

      def soap_client
        Magento::Soap.new(
          hostname: config['export_configuration']['soap']['hostname'],
          username: config['export_configuration']['soap']['username'],
          api_key: config['export_configuration']['soap']['api_key'],
        )
      end

      def database_adapter
        Magento::SQL.new(
          database: config['export_configuration']['database']['database'],
          host: config['export_configuration']['database']['host'],
          user: config['export_configuration']['database']['user'],
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
        base_required_keys = [
          %w(export_configuration),
          %w(export_configuration soap hostname),
          %w(export_configuration soap username),
          %w(export_configuration soap api_key),
        ]

        product_required_keys = [
          %w(export_configuration database host),
          %w(export_configuration database port),
          %w(export_configuration database database),
          %w(export_configuration database user),
          %w(export_configuration database password),
        ]

        required_keys = base_required_keys + (@object_type == 'product' ? product_required_keys : [])

        required_keys.each do |keys|
          raise InvalidConfigError, "missing required key '#{keys.join(' > ')}'" unless config.dig(*keys)
        end
      end
    end
  end
end
