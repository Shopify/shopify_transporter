# frozen_string_literal: true
require 'shopify_transporter/exporters/magento/database_cache'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe DatabaseCache do
        let(:table_data) {
          [
            {
              'parent_id' => '0',
              'child_id' => '1',
            },
            {
              'parent_id' => '0',
              'child_id' => '2',
            },
            {
              'parent_id' => '0',
              'child_id' => '3',
            },
            {
              'parent_id' => '4',
              'child_id' => '5',
            },
          ]
        }

        it 'reads mappings from the file for the given table' do
          file_data = "parent_id,child_id#{$/}"
          table_data.each { |row| file_data += row.values.to_csv }

          in_temp_folder do
            FileUtils.mkdir_p(DatabaseCache::DB_CACHE_FOLDER)
            File.open("#{DatabaseCache::DB_CACHE_FOLDER}/test_table.csv", 'w') { |file| file << file_data }

            db_cache = described_class.new
            output_data = db_cache.table('test_table')
            table_data.each_with_index do |data, index|
              expect(output_data[index]['parent_id']).to eq(data['parent_id'])
              expect(output_data[index]['child_id']).to eq(data['child_id'])
            end
          end
        end

        it 'caches the data read from the table and does not read the file multiple times' do
          expect(CSV).to receive(:read).and_return(table_data).once

          db_cache = described_class.new
          db_cache.table('test_table')
          expect(db_cache.table('test_table')).to eq(table_data)
        end
      end
    end
  end
end
