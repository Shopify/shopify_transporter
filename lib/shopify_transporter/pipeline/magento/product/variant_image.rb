# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Product
        class VariantImage < Pipeline::Stage
          def convert(hash, record)
            return {} unless hash['images'].present? && hash['parent_id'].present?
            variants = record['variants']
            parent_images = record['images'] || []

            record.merge(
              {
                images: parent_images + [foo(hash)],
                variants: with_images(variants)
              }.deep_stringify_keys
            )
          end

          def foo(x)
            { 'src' => variant_image_url(x) }
          end

          def with_images(variants)
            variants.map do |variant|
              {
                'variant_image' => {
                  'src' => variant_image_url(variant),
                }
              }
            end
          end

          def variant_image_url(input)
            return input['images']['url'] if input['images'].is_a?(Hash)
            input['images'].sort_by { |image| image['position'] }.first['url']
          end
        end
      end
    end
  end
end
