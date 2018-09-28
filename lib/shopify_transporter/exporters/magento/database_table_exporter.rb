# frozen_string_literal: true
require 'sequel'

module ShopifyTransporter
  module Exporters
    module Magento
      class DatabaseTableExporter
        BATCH_SIZE = 1000
        DB_CACHE_FOLDER = './cache/magento_db'

        def initialize(database_adapter)
          @database_adapter = database_adapter
          FileUtils.mkdir_p(DB_CACHE_FOLDER)
        end

        def export_table(table_name, index_column)
          export_file_path = "#{DB_CACHE_FOLDER}/#{table_name}.csv"

          return if File.file? export_file_path

          index_key = index_column.to_sym

          @database_adapter.connect do |db|
            ordered_table = db
              .from(table_name)
              .order(index_key)

            headers = ordered_table.columns

            write_headers(export_file_path, headers)

            in_batches(ordered_table, index_key) do |batch|
              write_batch(export_file_path, headers, batch)
            end
          end
        end

        private

        def write_headers(export_file_path, headers)
          File.open(export_file_path, 'w') do |file|
            file << headers.to_csv
          end
        end

        def write_batch(export_file_path, headers, batch)
          File.open(export_file_path, 'a') do |file|
            batch.each do |row|
              data = headers.map { |header| row[header] }
              file << data.to_csv
            end
          end
        end

        def in_batches(table, index_key)
          current_id = table.first[index_key]
          max_id = table.last[index_key]

          while current_id <= max_id
            batch = table.where(index_key => current_id...(current_id + BATCH_SIZE))
            yield batch
            current_id += BATCH_SIZE
          end
        end
      end
    end
  end
end
