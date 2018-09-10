# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    RSpec.describe Exporter do
      class SomePlatformExporter
        def export
          [{ foo: 'bar' }]
        end
      end

      def tmpfile(content, ext)
        file = Tempfile.new(['test', ext])
        file.puts YAML.dump(content)
        file.close
        file
      end

      def default_config
        {
          "platform_type" => 'Magento',
          "object_types" => {
            "customer" => {
              "record_key" => 'email',
              "key_required" => true,
              "pipeline_stages" => %w(TopLevelAttributes),
            },
          },
          "export_configuration" => {
            "soap" => {
              "hostname" => 'magento.host',
              "username" => 'something',
              "api_key" => 'a_key',
            },
            "store_id" => 1,
          },
        }
      end

      it 'writes exported data to file' do
        config_file = tmpfile(default_config, '.yml')

        expect(Magento::MagentoExporter)
          .to receive(:for)
          .and_return(SomePlatformExporter.new)

        exporter = Exporter.new(config_file.path, :unused)
        expect { exporter.run }.to output(JSON.pretty_generate([{ foo: 'bar' }]) + $INPUT_RECORD_SEPARATOR).to_stdout
      end

      it 'raises InvalidConfigError if config file does not exist' do
        config_filename = 'nonexistent_config.yml'

        error_message = "Invalid configuration: cannot find file name 'nonexistent_config.yml'"

        expect { Exporter.new(config_filename, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      it 'raises InvalidConfigError if config file is missing username' do
        config_without_username = default_config.tap { |cfg| cfg['export_configuration']['soap'].delete('username') }
        config_file = tmpfile(config_without_username, '.yml')

        error_message = "Invalid configuration: missing required key 'username'"

        expect { Exporter.new(config_file.path, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      it 'raises InvalidConfigError if config file is missing hostname' do
        config_without_hostname = default_config.tap { |cfg| cfg['export_configuration']['soap'].delete('hostname') }
        config_file = tmpfile(config_without_hostname, '.yml')

        error_message = "Invalid configuration: missing required key 'hostname'"

        expect { Exporter.new(config_file.path, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      it 'raises InvalidConfigError if config file is missing export configuration' do
        config_without_export_configuration = default_config.tap { |cfg| cfg.delete('export_configuration') }
        config_file = tmpfile(config_without_export_configuration, '.yml')

        error_message = "Invalid configuration: missing required key 'export_configuration'"

        expect { Exporter.new(config_file.path, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      it 'raises InvalidConfigError if config file is missing store id' do
        config_without_store_id = default_config.tap { |cfg| cfg['export_configuration'].delete('store_id') }
        config_file = tmpfile(config_without_store_id, '.yml')

        error_message = "Invalid configuration: missing required key 'store_id'"

        expect { Exporter.new(config_file.path, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      it 'raises InvalidConfigError if config file is missing api key' do
        config_without_store_id = default_config.tap { |cfg| cfg['export_configuration']['soap'].delete('api_key') }
        config_file = tmpfile(config_without_store_id, '.yml')

        error_message = "Invalid configuration: missing required key 'api_key'"

        expect { Exporter.new(config_file.path, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end
    end
  end
end
