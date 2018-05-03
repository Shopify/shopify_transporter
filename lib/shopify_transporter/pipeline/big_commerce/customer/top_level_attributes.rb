# frozen_string_literal: true
require_relative '../../stage'
require_relative '../../../shopify'
module ShopifyTransporter
  module Pipeline
    module BigCommerce
      module Customer
        class TopLevelAttributes < Pipeline::Stage
          def convert(hash, record)
            accumulator = TopLevelAttributesAccumulator.new(record)
            accumulator.accumulate(hash)
          end

          class TopLevelAttributesAccumulator < Shopify::AttributesAccumulator
            COLUMN_MAPPING = {
              'First Name' => 'first_name',
              'Last Name' => 'last_name',
              'Email Address' => 'email',
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
