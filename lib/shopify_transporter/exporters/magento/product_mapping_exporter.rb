# frozen_string_literal: true
require 'sequel'
require 'English'

module ShopifyTransporter
  module Exporters
    module Magento
      class ProductMappingExporter
        BATCH_SIZE = 1000

        def initialize(database_adapter: database_adapter)
          @database_adapter = database_adapter
        end

        def extract_mappings
          write_headers

          @database_adapter do |db|
            ordered_mappings = db
              .from(:catalog_product_relation)
              .order(:parent_id)
            current_id = ordered_mappings.first[:parent_id]
            max_id = ordered_mappings.last[:parent_id]

            while current_id < max_id
              mappings_batch = ordered_mappings.where(parent_id: current_id...(current_id + BATCH_SIZE))
              write_data(mappings_batch)
              current_id += BATCH_SIZE
            end
          end
        end

        private

        def write_headers
          File.open(@filename, 'w') do |file|
            file << "product_id,associated_product_id#{$INPUT_RECORD_SEPARATOR}"
          end
        end

        def write_data(mappings)
          File.open(@filename, 'a') do |file|
            mappings.each do |mapping|
              file << "#{mapping[:parent_id]},#{mapping[:child_id]}#{$INPUT_RECORD_SEPARATOR}"
            end
          end
        end
      end
    end
  end
end
