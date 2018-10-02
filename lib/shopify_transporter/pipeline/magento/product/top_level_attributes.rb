# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Product
        class TopLevelAttributes < Pipeline::Stage
          def convert(hash, record)
            warn_if_too_many_options(hash)
            accumulator = TopLevelAttributesAccumulator.new(record)
            accumulator.accumulate(hash)
          end

          private

          MAX_OPTION_COUNT = 3

          def too_many_options?(input)
            input["option#{MAX_OPTION_COUNT + 1}_name"].present?
          end

          def warn_if_too_many_options(input)
            if too_many_options?(input)
              $stderr.puts "Warning: Product #{input['product_id']} has too many options."\
              " Only the first #{MAX_OPTION_COUNT} options will be converted."
            end
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
              append_images_to_current_record!(input) if input['images'].present?
              attributes['tags'] = product_tags(input) if input['tags'].present?
              attributes['options'] = product_options(input) if input['option1_name'].present?
              attributes
            end

            def published?(input)
              input['visibility'].present? && input['visibility'].to_i != 1
            end

            def apply_image_column_mapping(input_image)
              {
                'src' => input_image['url'],
                'position' => input_image['position'],
                'alt' => image_alt_text(input_image['label']),
              }
            end

            def construct_images(input)
              return [apply_image_column_mapping(input['images'])] if input['images'].is_a?(Hash)
              images = input['images'].map do |image|
                apply_image_column_mapping(image).compact
              end
              images.sort_by { |image| image['position'] }
            end

            def append_images_to_current_record!(input)
              images = construct_images(input)
              if @output['images'].present?
                @output['images'].concat(images)
              else
                @output['images'] = images
              end
            end

            def product_options(input)
              %w(option1_name option2_name option3_name).map do |option_name|
                { 'name' => input[option_name] }
              end
            end

            def image_alt_text(label)
              if label.is_a? String
                label
              end
            end

            def product_tags(input)
              return input['tags']['name'] if input['tags'].is_a?(Hash)
              input['tags'].map { |tag| tag['name'] }.join(', ')
            end
          end
        end
      end
    end
  end
end
