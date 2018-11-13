# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Product
        class TopLevelVariantAttributes < Pipeline::Stage
          def convert(hash, record)
            return {} unless record.key?('variants')
            variant = record['variants'].find do |product|
              product['product_id'] == hash['product_id']
            end
            return {} unless variant.present?
            accumulator = TopLevelVariantAttributesAccumulator.new(variant)
            accumulator.accumulate(hash) #THIS MUTATES RECORD
            record
          end

          class TopLevelVariantAttributesAccumulator < Shopify::AttributesAccumulator
            COLUMN_MAPPING = {
              'sku' => 'sku',
              'weight' => 'weight',
              'price' => 'price',
              'inventory_quantity' => 'inventory_qty',
            }

            def accumulate(input)
              accumulate_attributes(map_from_key_to_val(COLUMN_MAPPING, input))
              accumulate_attributes(variant_options(input))
            end

            private

            def input_applies?(input)
              input.present? && input['type'] == 'simple'
            end

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
