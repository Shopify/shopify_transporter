# frozen_string_literal: true
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Shopify
    RSpec.describe Order do
      let(:top_level_attributes) do
        %w( 
          name  email  financial_status  fulfillment_status  currency
          buyer_accepts_marketing  cancel_reason  cancelled_at  closed_at  tags  note 
          phone  referring_site  processed_at  source_name  total_discounts  total_weight  total_tax
        )
      end

      let(:address_attributes) do
        %w(
          company name phone first_name last_name address1 address2 city province province_code zip country country_code 
        )
      end

      let(:line_item_attributes) do
        %w(
          name quantity price discount compare_at_price sku requires_shipping taxable fulfillment_status
        )
      end

      let(:tax_line_attributes) do
        %w(
          tax_1_title tax_1_price tax_1_rate
          tax_2_title tax_2_price tax_2_rate
          tax_3_title tax_3_price tax_3_rate
        )
      end

      let(:metafield_attributes) do
        %w(namespace key value value_type)
      end

      let(:shipping_address_prefix) { "shipping_" }
      let(:billing_address_prefix) { "billing_" }

      let(:shipping_address_attributes) do
        address_attributes.map { |attribute| "#{shipping_address_prefix}#{attribute}" }
      end

      let(:billing_address_attributes) do
        address_attributes.map { |attribute| "#{billing_address_prefix}#{attribute}" }
      end

      it '#header matches the transporter app template' do
        expected_header = File.open('spec/files/transporter_csv_templates/orders.csv', &:readline)
        expect(described_class.header).to eq(expected_header)
      end
     
      context '#to_csv' do
        it 'outputs the top level attributes correctly' do
          order_hash = FactoryBot.build(:shopify_order_hash, :with_shipping_address, :with_billing_address)
          actual_csv = described_class.new(order_hash).to_csv
          expected_csv = top_level_attributes_row(order_hash)
          expect(actual_csv).to eq(expected_csv)
        end

        it 'outputs line items correctly' do
          order_hash = FactoryBot.build(:shopify_order_hash, :with_line_items, tax_line_count: 0)
          actual_csv = described_class.new(order_hash).to_csv
          expected_csv = [
            top_level_attributes_row(order_hash),
            line_item_attributes_row(order_hash, order_hash['line_items'].first),
          ].join
          expect(actual_csv).to eq(expected_csv) 
        end

        it 'outputs metafields correctly' do
          order_hash = FactoryBot.build(:shopify_order_hash, :with_metafields)
          actual_csv = described_class.new(order_hash).to_csv
          expected_csv = [
            top_level_attributes_row(order_hash),
            metafield_rows(order_hash),
          ].join
          expect(actual_csv).to eq(expected_csv) 
        end

        it 'outputs line items with tax lines correctly' do
          order_hash = FactoryBot.build(:shopify_order_hash, :with_line_items)
          actual_csv = described_class.new(order_hash).to_csv
          expected_csv = [
            top_level_attributes_row(order_hash),
            line_item_attributes_row(order_hash, order_hash['line_items'].first),
          ].join
          expect(actual_csv).to eq(expected_csv) 
        end
      end

      def address_values(hash)
        return Array.new(address_attributes.size, nil) if hash.blank?
        hash.values_at(*address_attributes)
      end

      def top_level_attributes_row(hash)
        [
          *hash.values_at(*top_level_attributes),
          *address_values(hash['shipping_address']), 
          *address_values(hash['billing_address']), 
          *Array.new(line_item_attributes.size, nil),
          *Array.new(tax_line_attributes.size, nil),
          *Array.new(metafield_attributes.size, nil),
        ].to_csv
      end
      
      def tax_line_values(tax_lines)
        tax_lines ||= []
        tax_line_keys = ['title', 'price', 'rate']

        (1..3).each_with_object([]) do |tax_line_number, values|
          if tax_lines.size >= tax_line_number
            values << tax_line_keys.map { |k| tax_lines[tax_line_number - 1][k] }
          else
            values << Array.new(tax_line_keys.size, nil)
          end
        end.flatten
      end

      def line_item_attributes_row(hash, line_item_hash)
        [
          *hash.slice(*described_class.keys).values_at(*top_level_attributes),
          *Array.new(address_attributes.size, nil),
          *Array.new(address_attributes.size, nil),
          *line_item_hash.values_at(*line_item_attributes),
          *tax_line_values(line_item_hash['tax_lines']),
          *Array.new(metafield_attributes.size, nil),
        ].to_csv
      end

      def metafield_rows(hash)
        hash['metafields'].map do |metafield|
          [
            *hash.slice(*described_class.keys).values_at(*top_level_attributes),
            *Array.new(address_attributes.size, nil),
            *Array.new(address_attributes.size, nil),
            *Array.new(line_item_attributes.size, nil),
            *Array.new(tax_line_attributes.size, nil),
            *metafield.values_at(*metafield_attributes),
          ].to_csv
        end.join
      end
    end
  end
end
