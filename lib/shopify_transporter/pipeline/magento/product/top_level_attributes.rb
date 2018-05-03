# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Product
        class TopLevelAttributes < Pipeline::Stage
          def convert(hash, record)
            accumulator = TopLevelAttributesAccumulator.new(record)
            accumulator.accumulate(hash)
          end

          class TopLevelAttributesAccumulator < Shopify::AttributesAccumulator
            COLUMN_MAPPING = {
              'sku' => 'sku',
              'name' => 'title',
              'description' => 'body_html',
            }

            private

            def input_applies?(_input)
              true
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
