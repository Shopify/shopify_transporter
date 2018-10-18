# frozen_string_literal: true
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Shopify
    RSpec.describe Customer do
      let(:top_level_attributes) { %w(first_name last_name email phone accepts_marketing tags note tax_exempt).freeze }
      let(:address_attributes) { %w(company address1 address2 city province province_code zip country country_code).freeze }
      let(:metafield_attributes) { %w(namespace key value value_type).freeze }
      let(:shared_address_attributes) { %w(first_name last_name phone).freeze }

      describe '.header' do
        it 'returns the correct header' do
          expect(described_class.header).to eq(
            'First Name,Last Name,Email,Phone,Accepts Marketing,' \
            'Tags,Note,Tax Exempt,Company,Address1,Address2,City,' \
            'Province,Province Code,Zip,Country,Country Code,' \
            'Metafield Namespace,Metafield Key,Metafield Value,Metafield Value Type' \
            "#{$/}"
          )
        end
      end

      describe '#to_csv' do
        it 'produces a single row when only top level customer attributes exist' do
          hash = FactoryBot.build(:shopify_customer_hash)
          expect(described_class.new(hash).to_csv).to eq(top_level_attributes_row(hash))
        end

        it 'can produce the additonal metafield row when a single metafield exists' do
          hash = FactoryBot.build(:shopify_customer_hash, :with_metafields)
          expect(described_class.new(hash).to_csv).to eq(
            [
              top_level_attributes_row(hash),
              metafield_row(hash, hash['metafields'][0]),
            ].join
          )
        end

        it 'produces a row for each metafield when multiple metafields exist' do
          hash = FactoryBot.build(:shopify_customer_hash, :with_metafields, metafield_count: 2)
          expect(described_class.new(hash).to_csv).to eq(
            [
              top_level_attributes_row(hash),
              metafield_row(hash, hash['metafields'][0]),
              metafield_row(hash, hash['metafields'][1]),
            ].join
          )
        end

        it 'can merge the default address into the top level row when a single addresss exists' do
          hash = FactoryBot.build(:shopify_customer_hash, :with_addresses)
          expect(described_class.new(hash).to_csv).to eq(
            [
              top_level_attributes_row(hash)
            ].join
          )
        end

        it 'produces a row for each address when multiple addresses exist' do
          hash = FactoryBot.build(:shopify_customer_hash, :with_addresses, address_count: 2)
          expect(described_class.new(hash).to_csv).to eq(
            [
              top_level_attributes_row(hash),
              address_row(hash, hash['addresses'][1]),
            ].join
          )
        end

        it 'produces rows with overridden last_name/first_name/phone if those values exist in the address' do
          hash = FactoryBot.build(
              :shopify_customer_hash,
              addresses:  [
                FactoryBot.build(:address),
                FactoryBot.build(:address, first_name: "custom first", last_name: "custom last", phone: "custom phone")
              ]
          )
          expect(described_class.new(hash).to_csv).to eq(
            [
              top_level_attributes_row(hash),
              address_row(hash, hash['addresses'][1]),
            ].join
          )
        end

        it 'produces rows for addresses and metafields when the customer contains both' do
          hash = FactoryBot.build(:shopify_customer_hash, :with_metafields, :with_addresses)
          expect(described_class.new(hash).to_csv).to eq(
            [
              top_level_attributes_row(hash),
              metafield_row(hash, hash['metafields'][0]),
            ].join
          )
        end
      end

      def top_level_attributes_row(hash)
        if hash['addresses'].present? && hash['addresses'][0].present?
          [
            *hash.values_at(*top_level_attributes),
            *hash['addresses'][0].values_at(*address_attributes),
            *Array.new(metafield_attributes.count, nil),
          ].to_csv
        else
          [
            *hash.values_at(*top_level_attributes),
            *Array.new(metafield_attributes.count + address_attributes.count, nil),
          ].to_csv
        end
      end

      def address_row_top_level_values(hash, address_hash)
        hash.slice('first_name', 'last_name', 'email', 'phone')
          .merge(address_hash.slice(*shared_address_attributes).compact)
          .values_at(*top_level_attributes)
      end

      def address_row(hash, address_hash)
        [
          *address_row_top_level_values(hash, address_hash),
          *address_hash.values_at(*address_attributes),
          *Array.new(metafield_attributes.count, nil),
        ].to_csv
      end

      def metafield_row(hash, metafield_hash)
        [
          *hash.slice('email', 'phone').values_at(*top_level_attributes),
          *Array.new(address_attributes.count, nil),
          *metafield_hash.values_at(*metafield_attributes),
        ].to_csv
      end
    end
  end
end
