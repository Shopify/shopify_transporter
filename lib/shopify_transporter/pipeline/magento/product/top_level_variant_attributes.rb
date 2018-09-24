# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Product
        class TopLevelVariantAttributes < Pipeline::Stage
          def convert(hash, record)
            accumulator = TopLevelVariantAttributesAccumulator.new(record['variants'])
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

            def accumulate_attributes(attributes)
              @output.delete_if { |product| product['sku'] == attributes['sku'] }
              @output << attributes
            end
          end
        end
      end
    end
  end
end
