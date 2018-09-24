# frozen_string_literal: true
require 'sequel'
require 'English'
require_relative './magento_helpers'

module ShopifyTransporter
  module Exporters
    module Magento
      class ProductMappingExporter
        include MagentoHelpers

        def initialize(database_adapter)
          @database_adapter = database_adapter
        end

        def write_mappings(filename)
          write_headers(filename)

          @database_adapter.connect do |db|
            ordered_mappings = db
              .from(:catalog_product_relation)
              .order(:parent_id)

            in_batches(ordered_mappings, :parent_id) do |mappings_batch|
              write_data(mappings_batch, filename)
            end
          end
        end

        private

        def write_headers(filename)
          File.open(filename, 'w') do |file|
            file << "product_id,associated_product_id#{$INPUT_RECORD_SEPARATOR}"
          end
        end

        def write_data(mappings, filename)
          File.open(filename, 'a') do |file|
            mappings.each do |mapping|
              file << "#{mapping[:parent_id]},#{mapping[:child_id]}#{$INPUT_RECORD_SEPARATOR}"
            end
          end
        end
      end
    end
  end
end
