# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Product
        class TopLevelVariantAttributes < Pipeline::Stage
          def convert(hash, record)
            return unless input_applies?(hash)
            simple_product_in_magento_format = record['variants'].select do |product|
              product['product_id'] == hash['product_id']
            end.first
            accumulator = TopLevelVariantAttributesAccumulator.new(simple_product_in_magento_format)
            accumulator.accumulate(hash)
          end

          def input_applies?(input)
            true unless input['parent_id'].nil?
          end

          class TopLevelVariantAttributesAccumulator < Shopify::AttributesAccumulator
            COLUMN_MAPPING = {
              'sku' => 'sku',
              'weight' => 'grams',
              'price' => 'price',
              'inventory_quantity' => 'inventory_qty',
            }

            def accumulate(input)
              accumulate_attributes(map_from_key_to_val(COLUMN_MAPPING, input))
              accumulate_attributes(variant_options(input))
            end

            private

            def variant_options(input)
              {
                'option1' => input['option1_value'],
                'option2' => input['option2_value'],
                'option3' => input['option3_value'],
              }.compact
            end
          end
        end
      end
    end
  end
end
