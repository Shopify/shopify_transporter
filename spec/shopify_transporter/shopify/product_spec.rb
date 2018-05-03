# frozen_string_literal: true
require 'shopify_transporter/shopify/product'
require 'csv'

module ShopifyTransporter
  module Shopify
    RSpec.describe Product do
      let(:top_level_attributes) do
        %w(
          handle title body_html vendor product_type tags template_suffix published_scope published published_at
          option1_name option1_value option2_name option2_value option3_name option3_value variant_sku
          metafields_global_title_tag metafields_global_description_tag
        ).freeze
      end

      let(:metafield_attributes) { %w(namespace key value value_type).freeze }

      it '#header matches the transporter app template' do
        expected_header = File.open('spec/files/transporter_csv_templates/products.csv', &:readline)
        expect(described_class.header).to eq(expected_header)
      end
      it '#columns matches the keys in the shopify product api' do
        expect(described_class.columns).to eq(
          %w(
            handle title body_html vendor product_type tags template_suffix published_scope published published_at
            option1_name option1_value option2_name option2_value option3_name option3_value variant_sku
            metafields_global_title_tag metafields_global_description_tag
            metafield_namespace metafield_key metafield_value metafield_value_type
            variant_grams variant_inventory_tracker variant_inventory_qty variant_inventory_policy
            variant_fulfillment_service variant_price variant_compare_at_price variant_requires_shipping
            variant_taxable variant_barcode image_attachment image_src image_position image_alt_text
            variant_image variant_weight_unit variant_tax_code
          )
        )
      end

      context '#to_csv' do
        it 'outputs the top level attributes successfully' do
          product = FactoryBot.build(:shopify_product)
          actual_csv = described_class.new(product).to_csv
          expect(actual_csv).to eq(top_level_attributes_row(product))
        end

        it 'outputs product metafields successfully' do
          product = FactoryBot.build(:shopify_product, :with_metafields, metafield_count: 2)
          actual_csv = described_class.new(product).to_csv
          expected_csv = [
            top_level_attributes_row(product),
            metafield_row(product, product['metafields'][0]),
            metafield_row(product, product['metafields'][1]),
          ].join

          expect(actual_csv).to eq(expected_csv)
        end

        it 'outputs product variants successfully' do
          product = FactoryBot.build(:shopify_product, :with_variants, variant_count: 2)
          actual_csv = described_class.new(product).to_csv
          expected_csv = [
            top_level_attributes_row(product),
            variant_row(product, product['variants'][0]),
            variant_row(product, product['variants'][1]),
          ].join

          expect(actual_csv).to eq(expected_csv)
        end

        it 'outputs variant metafields successfully' do
          product = FactoryBot.build(:shopify_product, :with_variants, variant_count: 1, variant_metafield_count: 2)
          actual_csv = described_class.new(product).to_csv
          variant = product['variants'][0]
          expected_csv = [
            top_level_attributes_row(product),
            variant_row(product, variant),
            variant_metafield_row(product, variant, variant['metafields'][0]),
            variant_metafield_row(product, variant, variant['metafields'][1]),
          ].join

          expect(actual_csv).to eq(expected_csv)
        end

        it 'outputs product images successfully' do
          product = FactoryBot.build(:shopify_product, :with_images, image_count: 2)
          actual_csv = described_class.new(product).to_csv
          expected_csv = [
            top_level_attributes_row(product),
            image_row(product, product['images'][0]),
            image_row(product, product['images'][1]),
          ].join

          expect(actual_csv).to eq(expected_csv)
        end
      end

      it 'works if the keys in the hash are ordered differently' do
        product = {
          'title' => 'Test Title',
          'product_type' => 'Product Type',
          'handle' => 'Product Handle'
        }
        actual_csv = described_class.new(product).to_csv
        expected_csv = [
          'Product Handle', 'Test Title', nil, nil, 'Product Type',
          *Array.new(described_class.columns.length - 5, nil)
        ].to_csv

        expect(actual_csv).to eq(expected_csv)
      end

      def top_level_attributes_row(hash)
        attributes_before_options = %w(
          handle title body_html vendor product_type tags template_suffix published_scope published published_at
        )
        attributes_after_options = %w(
          variant_sku metafields_global_title_tag metafields_global_description_tag
        )
        [
          *hash.values_at(*attributes_before_options),
          hash['options'][0]['name'], nil, hash['options'][1]['name'], nil, hash['options'][2]['name'],
          nil, *hash.values_at(*attributes_after_options),
          *Array.new(described_class.columns.length - top_level_attributes.length, nil),
        ].to_csv
      end

      def metafield_row(hash, metafield_hash)
        [
          hash['handle'],
          *Array.new(described_class.columns.index('metafield_namespace') - 1, nil),
          *metafield_hash.values_at(*metafield_attributes),
          *Array.new(described_class.columns.length - described_class.columns.index('variant_grams'), nil),
        ].to_csv
      end

      def variant_metafield_row(hash, variant_hash, variant_metafield_hash)
        [
          hash['handle'],
          *nil_array_for_row('handle', 'option1_name'),
          nil, variant_hash['option1'], nil, variant_hash['option2'], nil, variant_hash['option3'],
          *nil_array_for_row('option3_value', 'metafield_namespace'),
          *variant_metafield_hash.values_at(*metafield_attributes),
          *Array.new(described_class.columns.length - described_class.columns.index('variant_grams'), nil),
        ].to_csv
      end

      def variant_row(hash, variant_hash)
        variant_values_set2 = %w(
          grams inventory_tracker inventory_qty inventory_policy
          fulfillment_service price compare_at_price requires_shipping
          taxable barcode
        )
        variant_values_set3 = %w(
          weight_unit tax_code
        )
        [
          *hash['handle'],
          *nil_array_for_row('handle', 'option1_name'),
          nil, variant_hash['option1'], nil, variant_hash['option2'], nil, variant_hash['option3'],
          variant_hash['sku'],
          *nil_array_for_row('variant_sku', 'variant_grams'),
          *variant_hash.values_at(*variant_values_set2),
          *nil_array_for_row('variant_barcode', 'variant_image'),
          variant_hash['variant_image']['src'],
          *variant_hash.values_at(*variant_values_set3),
        ].to_csv
      end

      def image_row(hash, image_hash)
        [
          hash['handle'],
          *nil_array_for_row('handle', 'image_attachment'),
          *image_hash.values_at('attachment', 'src', 'position', 'alt'),
          *nil_array(3),
        ].to_csv
      end

      def nil_array_for_row(start_column, end_column)
        nil_array(described_class.columns.index(end_column) - described_class.columns.index(start_column) - 1)
      end

      def nil_array(count)
        Array.new(count, nil)
      end
    end
  end
end
