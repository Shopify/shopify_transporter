# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Product
        class VariantImage < Pipeline::Stage
          def convert(hash, record)
            return unless input_applied?(hash)
            accumulate(hash, record)
            add_variant_img_to_parent_image_array(record, hash)
          end

          def input_applied?(input)
            input['images'].present? && input['parent_id'].present?
          end


          def accumulate(input, record)
            current_product = record['variants'].select do |variant|
              variant['product_id'] == input['product_id']
            end.first
            current_product.merge!(
              {
                'variant_image': {
                  'src': variant_image_url(input)
                }
              }
            )
          end

          def variant_image_url(input)
            return input['images']['url'] if input['images'].is_a?(Hash)
            input['images'].sort_by { |image| image['position'] }.first['url']
          end

          def add_variant_img_to_parent_image_array(record, input)
            record['images'] ||= []
            record['images'] << {
              'src': variant_image_url(input)
            }
          end
        end
      end
    end
  end
end
