# frozen_string_literal: true
require_relative '../stage'
require_relative '../../shopify'

module ShopifyTransporter
  module Pipeline
    module AllPlatforms
      class Metafields < ShopifyTransporter::Pipeline::Stage
        def convert(input, record)
          raise 'Metafields not specified.' unless metafields_specified(params)

          accumulator = MetafieldAttributesAccumulator.new(
            initial_value: record,
            metafields_to_extract: params['metafields'],
            metafield_namespace: params['metafield_namespace'] || ShopifyTransporter::DEFAULT_METAFIELD_NAMESPACE,
          )
          accumulator.accumulate(input)
        end

        private

        def metafields_specified(params)
          params['metafields'].class == Array && params['metafields'].any?
        end

        class MetafieldAttributesAccumulator < ShopifyTransporter::Shopify::AttributesAccumulator
          attr_reader :metafields_to_extract, :metafield_namespace

          def initialize(initial_value:, metafields_to_extract:, metafield_namespace:)
            @metafields_to_extract = metafields_to_extract
            @metafield_namespace = metafield_namespace
            super(initial_value)
          end

          private

          def input_applies?(input)
            attributes_present?(input, *metafields_to_extract)
          end

          def attributes_from(input)
            {
              'metafields' => extract_metafields(input),
            }
          end

          def extract_metafields(input)
            metafields_to_extract.map do |metafield_key|
              next if input[metafield_key].nil?
              shopify_metafield_hash(
                key: metafield_key,
                value: input[metafield_key],
                namespace: metafield_namespace
              )
            end.compact
          end
        end
      end
    end
  end
end
