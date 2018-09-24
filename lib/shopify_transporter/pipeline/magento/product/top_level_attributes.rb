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
            }

            private

            def input_applies?(input)
              true unless input['parent_id'].present?
            end

            def attributes_from(input)
              attributes = map_from_key_to_val(COLUMN_MAPPING, input)
              attributes['published'] = published?(input)
              attributes['published_scope'] = published?(input) ? 'global' : ''
              attributes['published_at'] = published?(input) ? input['updated_at'] : ''
              attributes['images'] = append_images(input) if input['images'].present?
              attributes
            end

            def published?(input)
              input['visibility'].present? && input['visibility'].to_i != 1
            end

            def append_images(input)
              images = input['images'].map do |image|
                {
                  'src': image['url'],
                  'position': image['position'],
                  'alt_text': image_alt_text(image['label']),
                }.compact
              end
              images.sort_by { |image| image['position'] }
            end

            def image_alt_text(label)
              if label.is_a? String
                label
              end
            end
          end
        end
      end
    end
  end
end
