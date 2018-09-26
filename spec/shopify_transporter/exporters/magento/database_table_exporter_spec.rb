# frozen_string_literal: true
require 'shopify_transporter/exporters/magento/database_table_exporter'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe DatabaseTableExporter do
        let(:database_adapter) { double('database_adapter') }
        let(:db) { double('sequel database connection') }

        around :each do |example|
          Tempfile.open('test_product_mappings.csv', Dir.tmpdir) do |file|
            @tempfile = file
            example.run
          end
        end

        describe '#export_table' do
          let(:table_data_batches) do
            [
              [
                {
                  id: 0,
                  name: 'test',
                },
                {
                  id: 1,
                  name: 'test1',
                },
              ],
              [
                {
                  id: 2,
                  name: 'test2',
                },
                {
                  id: 3,
                  name: 'test3',
                },
              ],
              [
                {
                  id: 4,
                  name: 'test4',
                },
              ],
            ]
          end

          let(:table_name) { 'product_relations' }
          let(:index_column) { 'id' }
          let(:mock_db_adapter) { double('database_adapter') }

          before :each do
            batch_size = 2

            stub_const('ShopifyTransporter::Exporters::Magento::DatabaseTableExporter::BATCH_SIZE', batch_size)

            mock_db_connection = double('db connection')
            mock_db_table = double("mock #{table_name} table")

            expect(mock_db_adapter).to receive(:connect) do |&block|
              block.call(mock_db_connection)
            end

            expect(mock_db_connection).to receive(:from).with(table_name).and_return(mock_db_table)
            expect(mock_db_table).to receive(:order).with(index_column).and_return(mock_db_table)
            expect(mock_db_table).to receive(:columns).and_return([:id, :name])
            expect(mock_db_table).to receive(:first).and_return(table_data_batches.first.first)
            expect(mock_db_table).to receive(:last).and_return(table_data_batches.last.last)

            batch_call = 0
            starting_id = 0
            expect(mock_db_table).to receive(:where) do |args|
              expect(args[index_column.to_sym]).to eq(starting_id...(starting_id + batch_size))
              batch_data = table_data_batches[batch_call]
              batch_call += 1
              starting_id += batch_size
              batch_data
            end.exactly(3).times
          end

          it 'exports the table in batches to the cache folder path for that table' do
            expected_output = "id,name#{$/}"
            table_data_batches.flatten.each { |object| expected_output += object.values.to_csv }

            in_temp_folder do
              database_table_exporter = described_class.new(mock_db_adapter)
              database_table_exporter.export_table(table_name, index_column)

              expected_output_file = "#{described_class::DB_CACHE_FOLDER}/#{table_name}.csv"

              expect(File.read(expected_output_file)).to eq(expected_output)
            end
          end

          it 'creates a new file every time' do
            expected_output = "id,name#{$/}"
            table_data_batches.flatten.each { |object| expected_output += object.values.to_csv }

            in_temp_folder do
              FileUtils.mkdir_p(described_class::DB_CACHE_FOLDER)
              expected_output_file = "#{described_class::DB_CACHE_FOLDER}/#{table_name}.csv"

              File.open(expected_output_file, 'w') { |file| file << 'test' }

              database_table_exporter = described_class.new(mock_db_adapter)
              database_table_exporter.export_table(table_name, index_column)
              expect(File.read(expected_output_file)).to eq(expected_output)
            end
          end
        end
      end
    end
  end
end
