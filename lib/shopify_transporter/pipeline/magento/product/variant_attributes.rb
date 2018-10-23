# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Product
        class VariantAttributes < Pipeline::Stage
          def convert(hash, record)
            accumulator = VariantAttributesAccumulator.new(record)
            accumulator.accumulate(hash)
          end

          class VariantAttributesAccumulator < Shopify::AttributesAccumulator
            def accumulate(current_product)
              if current_product['type'] == 'simple'
                @output['variants'] ||= []
                @output['variants'] << current_product
                @output
              end
            end
          end
        end
      end
    end
  end
end
