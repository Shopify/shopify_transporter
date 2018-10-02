# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    RSpec.describe Exporter do
      class SomePlatformExporter
        def initialize(_)
        end
        def key
          :foo
        end
        def export
          objects = [{ foo: 'bar' }, { baz: 'gud' }]
          objects.each do |object|
            yield object
          end
        end
      end

      def tmpfile(content, ext)
        file = Tempfile.new(['test', ext])
        file.puts content
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
          "extract_configuration" => {
            "soap" => {
              "hostname" => 'magento.host',
              "username" => 'something',
              "api_key" => 'a_key',
            },
            "database" => {
              "host" => 'magento.host',
              "port" => '1234',
              "database" => 'testdatabase',
              "user" => 'something',
              "password" => 'a_password',
            },
          },
        }
      end

      it 'writes exported data to stdout' do
        config_file = tmpfile(YAML.dump(default_config), '.yml')

        expect(Magento::MagentoExporter)
          .to receive(:for)
          .and_return(SomePlatformExporter)

        exporter = Exporter.new(config_file.path, :unused)

        expected_result = [{ 'foo' => 'bar' }, { 'baz' => 'gud' }]
        output = capture(:stdout) { exporter.run }
        expect(JSON.parse(output)).to eq(expected_result)
      end

      it 'raises InvalidConfigError if config file does not exist' do
        config_filename = 'nonexistent_config.yml'

        error_message = "Invalid configuration: cannot find file name 'nonexistent_config.yml'"

        expect { Exporter.new(config_filename, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      it 'raises InvalidConfigError if config file is missing username' do
        config_without_username = default_config.tap { |cfg| cfg['extract_configuration']['soap'].delete('username') }
        config_file = tmpfile(YAML.dump(config_without_username), '.yml')

        error_message = "Invalid configuration: missing required key 'extract_configuration > soap > username'"

        expect { Exporter.new(config_file.path, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      it 'raises InvalidConfigError if config file is missing hostname' do
        config_without_hostname = default_config.tap { |cfg| cfg['extract_configuration']['soap'].delete('hostname') }
        config_file = tmpfile(YAML.dump(config_without_hostname), '.yml')

        error_message = "Invalid configuration: missing required key 'extract_configuration > soap > hostname'"

        expect { Exporter.new(config_file.path, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      it 'raises InvalidConfigError if config file is missing export configuration' do
        config_without_extract_configuration = default_config.tap { |cfg| cfg.delete('extract_configuration') }
        config_file = tmpfile(YAML.dump(config_without_extract_configuration), '.yml')

        error_message = "Invalid configuration: missing required key 'extract_configuration'"

        expect { Exporter.new(config_file.path, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      it 'raises InvalidConfigError if config file is missing api key' do
        config = default_config.tap { |cfg| cfg['extract_configuration']['soap'].delete('api_key') }
        config_file = tmpfile(YAML.dump(config), '.yml')

        error_message = "Invalid configuration: missing required key 'extract_configuration > soap > api_key'"

        expect { Exporter.new(config_file.path, :unused) }
          .to raise_error(InvalidConfigError, error_message)
      end

      context 'when processing database configuration' do
        %w(host port database user password).each do |key|
          it "for products, raises an InvalidConfigError if the database key #{key} is missing." do
            config = default_config.tap { |cfg| cfg['extract_configuration']['database'].delete(key) }
            config_file = tmpfile(YAML.dump(config), '.yml')

            error_message = "Invalid configuration: missing required key 'extract_configuration > database > #{key}'"

            expect { Exporter.new(config_file.path, 'product') }
              .to raise_error(InvalidConfigError, error_message)
          end

          it "for non-product objects, does not raise an InvalidConfigError if the database key #{key} is missing." do
            config = default_config.tap { |cfg| cfg['extract_configuration']['database'].delete(key) }
            config_file = tmpfile(YAML.dump(config), '.yml')

            error_message = "Invalid configuration: missing required key 'extract_configuration > database > #{key}'"

            expect { Exporter.new(config_file.path, 'other_object') }.not_to raise_error
          end
        end
      end
    end
  end
end
