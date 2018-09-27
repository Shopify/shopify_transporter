# frozen_string_literal: true
require 'active_support/inflector'
require 'csv'
require_relative 'record'
require_relative 'attributes_helpers'

module ShopifyTransporter
  module Shopify
    class Product < Record
      TOP_LEVEL_ATTRIBUTES = %w(
        handle title body_html vendor product_type tags template_suffix published_scope published published_at
        option1_name option1_value option2_name option2_value option3_name option3_value variant_sku
        metafields_global_title_tag metafields_global_description_tag
      ).freeze

      VARIANT_PREFIX = 'variant_'

      VARIANT_ATTRIBUTES = %w(
        sku grams inventory_tracker inventory_qty inventory_policy
        fulfillment_service price compare_at_price requires_shipping
        taxable barcode weight_unit tax_code
      ).freeze

      class << self
        include AttributesHelpers

        def header
          [
            'Handle', 'Title', 'Body (HTML)', 'Vendor', 'Type', 'Tags', 'Template Suffix', 'Published Scope',
            'Published', 'Published At', 'Option1 Name', 'Option1 Value', 'Option2 Name', 'Option2 Value',
            'Option3 Name', 'Option3 Value', 'Variant SKU', 'Metafields Global Title Tag',
            'Metafields Global Description Tag', 'Metafield Namespace', 'Metafield Key', 'Metafield Value',
            'Metafield Value Type', 'Variant Grams', 'Variant Inventory Tracker', 'Variant Inventory Qty',
            'Variant Inventory Policy', 'Variant Fulfillment Service', 'Variant Price', 'Variant Compare At Price',
            'Variant Requires Shipping', 'Variant Taxable', 'Variant Barcode', 'Image Attachment', 'Image Src',
            'Image Position', 'Image Alt Text', 'Variant Image', 'Variant Weight Unit', 'Variant Tax Code'
          ].to_csv
        end

        def columns
          @columns ||= header.parse_csv.map do |header_column|
            header_column = 'product_type' if header_column == 'Type'
            normalize_string(header_column)
          end
        end

        def keys
          %w(handle).freeze
        end
      end

      def to_csv
        CSV.generate do |csv|
          csv << top_level_row_values
          metafield_row_values.each { |row| csv << row }
          variant_row_values.each { |row| csv << row }
          variant_metafield_row_values.each { |row| csv << row }
          image_row_values.each { |row| csv << row }
        end
      end

      def top_level_row_values
        base_hash.merge(record_hash.slice(*TOP_LEVEL_ATTRIBUTES)).tap do |product_hash|
          next if record_hash['options'].blank?

          product_hash['option1_name'] = record_hash['options'][0]['name']
          product_hash['option2_name'] = record_hash['options'][1]['name']
          product_hash['option3_name'] = record_hash['options'][2]['name']
        end.values
      end

      def variant_row_values
        return [] if record_hash['variants'].blank?
        record_hash['variants'].map do |variant_hash|
          variant = variant_hash.slice(*VARIANT_ATTRIBUTES)
          variant.transform_keys! { |k| "#{VARIANT_PREFIX}#{k}" }
          variant.merge!(variant_option_hash(variant_hash))
          variant['variant_image'] = variant_hash['variant_image'] && variant_hash['variant_image']['src']
          row_values_from(variant)
        end
      end

      def variant_metafield_row_values
        return [] if record_hash['variants'].blank?
        record_hash['variants'].flat_map do |variant_hash|
          next if variant_hash['metafields'].blank?
          variant_hash['metafields'].map do |metafield_hash|
            metafield = metafield_hash.slice(*METAFIELD_ATTRIBUTES)
            metafield.transform_keys! { |k| "#{METAFIELD_PREFIX}#{k}" }
            metafield.merge!(variant_option_hash(variant_hash))
            row_values_from(metafield) if self.class.has_values?(metafield)
          end.compact
        end.compact
      end

      def image_row_values
        return [] if record_hash['images'].blank?

        record_hash['images'].map do |image_hash|
          image = {
            'image_src' => image_hash['src'],
            'image_position' => image_hash['position'],
            'image_alt_text' => image_hash['alt'],
          }
          row_values_from(image) if self.class.has_values?(image)
        end.compact
      end

      def variant_option_hash(variant_hash)
        {
          'option1_value' => variant_hash['option1'],
          'option2_value' => variant_hash['option2'],
          'option3_value' => variant_hash['option3'],
        }
      end
    end
  end
end
