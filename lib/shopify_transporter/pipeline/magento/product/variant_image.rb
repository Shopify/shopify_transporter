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
<<<<<<< HEAD
            add_variant_image!(hash, record)
            add_variant_image_to_parent_images!(hash, record)
            record
=======
            accumulate(hash, record)
            add_variant_img_to_parent_image_array(record, hash)
>>>>>>> extract and convert variant images
          end

          def input_applied?(input)
            input['images'].present? && input['parent_id'].present?
          end

<<<<<<< HEAD
          def current_variant(input, record)
            record['variants'].select do |variant|
              variant['product_id'] == input['product_id']
            end.first
          end

          def add_variant_image!(input, record)
            current_variant(input, record).merge!(
              'variant_image' => {
                'src' => variant_image_url(input),
=======

          def accumulate(input, record)
            current_product = record['variants'].select do |variant|
              variant['product_id'] == input['product_id']
            end.first
            current_product.merge!(
              {
                'variant_image': {
                  'src': variant_image_url(input)
                }
>>>>>>> extract and convert variant images
              }
            )
          end

          def variant_image_url(input)
            return input['images']['url'] if input['images'].is_a?(Hash)
            input['images'].sort_by { |image| image['position'] }.first['url']
          end

<<<<<<< HEAD
          def add_variant_image_to_parent_images!(input, record)
            record['images'] ||= []
            record['images'] << {
              'src' => variant_image_url(input),
=======
          def add_variant_img_to_parent_image_array(record, input)
            record['images'] ||= []
            record['images'] << {
              'src': variant_image_url(input)
>>>>>>> extract and convert variant images
            }
          end
        end
      end
    end
  end
end
