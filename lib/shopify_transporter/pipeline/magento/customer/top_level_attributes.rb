# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Customer
        class TopLevelAttributes < Pipeline::Stage
          def convert(hash, record)
            accumulator = TopLevelAttributesAccumulator.new(record)
            accumulator.accumulate(hash)
            record.merge(accumulator.output)
          end

          class TopLevelAttributesAccumulator < Shopify::AttributesAccumulator
            COLUMN_MAPPING = {
              'firstname' => 'first_name',
              'lastname' => 'last_name',
              'email' => 'email',
            }

            private

            def input_applies?(_input)
              true
            end

            def attributes_from(input)
              attributes = COLUMN_MAPPING.each_with_object({}) do |(key, value), obj|
                obj[value] = input[key] if input[key]
              end
              attributes['accepts_marketing'] = accepts_marketing(input)
              attributes
            end

            def accepts_marketing(input)
              value = input['is_subscribed']
              return unless value.present?
              (value == '1').to_s
            end
          end
        end
      end
    end
  end
end
