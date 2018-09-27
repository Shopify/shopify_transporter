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
            add_variant_image!(hash, record)
            add_variant_image_to_parent_images!(hash, record)
            record
          end

          def input_applied?(input)
            input['images'].present? && input['parent_id'].present?
          end

          def current_variant(input, record)
            record['variants'].select do |variant|
              variant['product_id'] == input['product_id']
            end.first
          end

          def add_variant_image!(input, record)
            current_variant(input, record).merge!(
              'variant_image' => {
                'src' => variant_image_url(input),
              }
            )
          end

          def variant_image_url(input)
            return input['images']['url'] if input['images'].is_a?(Hash)
            input['images'].sort_by { |image| image['position'] }.first['url']
          end

          def add_variant_image_to_parent_images!(input, record)
            record['images'] ||= []
            record['images'] << {
              'src' => variant_image_url(input),
            }
          end
        end
      end
    end
  end
end
