# frozen_string_literal: true
require 'shopify_transporter/exporters/magento/product_mapping_exporter'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe ProductMappingExporter do
        around :each do |example|
          Tempfile.open('test_product_mappings.csv', Dir.tmpdir) do |file|
            @tempfile = file
            example.run
          end
        end

        describe '#initialize' do
          it 'initializes when provided the right values' do
            described_class.new(
              database: 'test',
              host: '127.0.0.1',
              port: 3306,
              user: 'dbuser',
              password: 'dbuserpassword',
              filename: @tempfile.path
            )
          end
        end

        describe '#extract_mappings' do
          it 'creates a new file' do
            expect(Sequel).to receive(:connect)

            File.open(@tempfile.path, 'w') do |file|
              file << "test data"
            end

            exporter = described_class.new(
              database: 'test',
              host: '127.0.0.1',
              port: 3306,
              user: 'dbuser',
              password: 'dbuserpassword',
              filename: @tempfile.path
            )

            exporter.extract_mappings

            expect(File.read(@tempfile.path)).to eq <<~EOS
              product_id,associated_product_id
              EOS
          end

          it 'writes the expected headers to the output file' do
            expect(Sequel).to receive(:connect)

            exporter = described_class.new(
              database: 'test',
              host: '127.0.0.1',
              port: 3306,
              user: 'dbuser',
              password: 'dbuserpassword',
              filename: @tempfile.path
            )

            exporter.extract_mappings

            expect(File.read(@tempfile.path)).to eq <<~EOS
              product_id,associated_product_id
              EOS
          end

          it 'uses Sequel to connect to the MySQL database with the provided parameters' do
            expect(Sequel).to receive(:connect).with(
              adapter: :mysql2,
              database: 'test',
              host: '127.0.0.1',
              port: 3306,
              user: 'dbuser',
              password: 'dbuserpassword',
            )

            exporter = described_class.new(
              database: 'test',
              host: '127.0.0.1',
              port: 3306,
              user: 'dbuser',
              password: 'dbuserpassword',
              filename: @tempfile.path
            )

            exporter.extract_mappings
          end

          describe 'fetching product batches and outputting to file' do
            subject do
              described_class.new(
                database: 'test',
                host: '127.0.0.1',
                port: 3306,
                user: 'dbuser',
                password: 'dbuserpassword',
                filename: @tempfile.path
              )
            end
            let(:db) { double('sequel database connection') }
            let(:mappings) { double('product mappings relation') }
            let(:ordered_mappings) { double('ordered product mapping relation') }

            let(:mappings) do
              [
                {
                  parent_id: 1,
                  child_id: 2,
                },
                {
                  parent_id: 3,
                  child_id: 4,
                },
                {
                  parent_id: described_class::BATCH_SIZE,
                  child_id: 5,
                },
                {
                  parent_id: described_class::BATCH_SIZE + 1,
                  child_id: 6,
                },
              ]
            end

            before :each do
              expect(Sequel).to receive(:connect) do |&block|
                block.call(db)
              end
            end

            it 'fetches product mappings in batches from the database' do
              expect(db).to receive(:from).and_return(mappings).ordered
              expect(mappings).to receive(:order).with(:parent_id).and_return(ordered_mappings).ordered

              expect(ordered_mappings).to receive(:first).and_return(parent_id: 1)
              expect(ordered_mappings).to receive(:last).and_return(parent_id: 2 * described_class::BATCH_SIZE)

              expect(ordered_mappings).to receive(:where).with(
                parent_id: 1...(1 + described_class::BATCH_SIZE)
              ).and_return(
                mappings[0..1]
              )
              expect(ordered_mappings).to receive(:where).with(
                parent_id: (1 + described_class::BATCH_SIZE)...(1 + 2 * described_class::BATCH_SIZE)
              ).and_return(
                mappings[2..3]
              )

              subject.extract_mappings
            end

            it 'writes product mappings to the external file specified' do
              expect(db).to receive(:from).and_return(mappings).ordered
              expect(mappings).to receive(:order).with(:parent_id).and_return(ordered_mappings).ordered

              expect(ordered_mappings).to receive(:first).and_return(parent_id: 1)
              expect(ordered_mappings).to receive(:last).and_return(parent_id: 2 * described_class::BATCH_SIZE)

              expect(ordered_mappings).to receive(:where).with(
                parent_id: 1...(1 + described_class::BATCH_SIZE)
              ).and_return(
                mappings[0..1]
              )
              expect(ordered_mappings).to receive(:where).with(
                parent_id: (1 + described_class::BATCH_SIZE)...(1 + 2 * described_class::BATCH_SIZE)
              ).and_return(
                mappings[2..3]
              )

              subject.extract_mappings

              expected_file_data = "product_id,associated_product_id\n"
              mappings.each do |mapping|
                expected_file_data += "#{mapping[:parent_id]},#{mapping[:child_id]}#{$INPUT_RECORD_SEPARATOR}"
              end

              expect(File.read(@tempfile.path)).to eq(expected_file_data)
            end
          end
        end
      end
    end
  end
end
