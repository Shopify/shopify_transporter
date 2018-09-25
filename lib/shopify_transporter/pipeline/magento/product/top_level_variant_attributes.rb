# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Product
        class TopLevelVariantAttributes < Pipeline::Stage
          def convert(hash, record)
            simple_product_in_magento_format = record['variants'].select do |product|
              product['product_id'] == hash['product_id']
            end[0]
            accumulator = TopLevelVariantAttributesAccumulator.new(simple_product_in_magento_format)
            accumulator.accumulate(hash)
          end

          class TopLevelVariantAttributesAccumulator < Shopify::AttributesAccumulator
            COLUMN_MAPPING = {
              'sku' => 'sku',
              'weight' => 'grams',
              'price' => 'price',
            }
            def input_applies?(input)
              true unless input['parent_id'].nil?
            end

            def attributes_from(input)
              map_from_key_to_val(COLUMN_MAPPING, input)
            end
          end
        end
      end
    end
  end
end
