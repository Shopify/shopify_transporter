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
              'name' => 'title',
              'description' => 'body_html',
              'url_key' => 'handle',
              'created_at' => 'created_at',
            }

            private

            def input_applies?(input)
              true unless input['parent_id'].present?
            end

            def attributes_from(input)
              attributes = map_from_key_to_val(COLUMN_MAPPING, input)
              attributes['published_scope'] = published_scope(input)
              attributes
            end

            def published_scope(input)
              value = input['visibility']
              return unless value.present?
              value == '1' ? 'web' : ' '
            end
          end
        end
      end
    end
  end
end
