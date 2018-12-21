# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/order/addresses_attribute'

module ShopifyTransporter::Pipeline::Magento::Order
  RSpec.describe AddressesAttribute, type: :helper do
    context '#convert' do

      it "does not fail if the billing address can't be found in the expected nested structure" do
        magento_order = FactoryBot.build(:magento_order)
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['billing_address']).to be_empty

        magento_order['items'] = {}
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['billing_address']).to be_empty

        magento_order['items']['result'] = {}
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['billing_address']).to be_empty

        magento_order['items']['result']['billing_address'] = {}
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['billing_address']).to be_empty
      end

      it "does not fail if the shipping address can't be found in the expected nested structure" do
        magento_order = FactoryBot.build(:magento_order)
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['shipping_address']).to be_empty

        magento_order['items'] = {}
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['shipping_address']).to be_empty

        magento_order['items']['result'] = {}
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['shipping_address']).to be_empty

        magento_order['items']['result']['shipping_address'] = {}
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['shipping_address']).to be_empty
      end

      it 'extracts shipping and billing address attributes from an input hash' do
        magento_order = FactoryBot.build(:magento_order, :with_billing_address, :with_shipping_address)

        shopify_order = described_class.new.convert(magento_order, {})

        expected_shopify_addresses = {
          "billing_address" => {
            first_name: 'billing test first name-1',
            last_name: 'billing test last name-1',
            name: 'billing test first name-1 billing test last name-1',
            phone: 'billing test telephone-1',
            address1: 'billing test street-1',
            city: 'billing test city-1',
            province_code: 'billing test region-1',
            zip: 'billing test postcode-1',
            country_code: 'billing test country-1',
            company: 'billing test company-1',
          },
          "shipping_address" => {
            first_name: 'shipping test first name-1',
            last_name: 'shipping test last name-1',
            name: 'shipping test first name-1 shipping test last name-1',
            phone: 'shipping test telephone-1',
            address1: 'shipping test street-1',
            city: 'shipping test city-1',
            province_code: 'shipping test region-1',
            zip: 'shipping test postcode-1',
            country_code: 'shipping test country-1',
            company: 'shipping test company-1',
          }
        }
        expect(shopify_order).to include(expected_shopify_addresses)
      end

      it 'Will purge the address if it has nonsense key value pair' do
        magento_order = FactoryBot.build(:magento_order, :with_billing_address_partially_in_unexpected_format,
          :with_shipping_address_partially_in_unexpected_format)

        shopify_order = described_class.new.convert(magento_order, {})

        expected_shopify_addresses = {
          "billing_address" => {
            first_name: 'billing test first name-1',
            last_name: nil,
            name: nil,
            phone: 'billing test telephone-1',
            address1: 'billing test street-1',
            city: 'billing test city-1',
            province_code: 'billing test region-1',
            zip: 'billing test postcode-1',
            country_code: 'billing test country-1',
            company: nil,
          },
          "shipping_address" => {
            first_name: 'shipping test first name-1',
            last_name: nil,
            name: nil,
            phone: nil,
            address1: 'shipping test street-1',
            city: 'shipping test city-1',
            province_code: 'shipping test region-1',
            zip: 'shipping test postcode-1',
            country_code: 'shipping test country-1',
            company: nil,
          }
        }
        expect(shopify_order).to include(expected_shopify_addresses)
      end
    end
  end
end
