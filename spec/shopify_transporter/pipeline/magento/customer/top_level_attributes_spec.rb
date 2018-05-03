# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/customer/top_level_attributes'

module ShopifyTransporter::Pipeline::Magento::Customer
  RSpec.describe TopLevelAttributes, type: :helper do
    context '#convert' do
      it 'extracts top level shopify customer attributes from an input hash' do
        magento_customer = FactoryBot.build(:magento_customer,
          firstname: 'test first name',
          lastname: 'test last name',
          email: 'test email',
          is_subscribed: '0',
        )
        shopify_customer = described_class.new.convert(magento_customer, {})
        expected_shopify_customer = {
          first_name: magento_customer['firstname'],
          last_name: magento_customer['lastname'],
          email: magento_customer['email'],
          accepts_marketing: 'false',
        }

        expect(shopify_customer).to include(expected_shopify_customer.deep_stringify_keys)
      end

      it 'sets accepts_marketing to true if is_subscribed is 1 in the magento customer input' do
        magento_customer = FactoryBot.build(:magento_customer, is_subscribed: '1')
        shopify_customer = described_class.new.convert(magento_customer, {})

        expect(shopify_customer).to include('accepts_marketing' => 'true')
      end

      it 'sets accepts_marketing to false if is_subscribed is 0 in the magento customer input' do
        magento_customer = FactoryBot.build(:magento_customer, is_subscribed: '0')
        shopify_customer = described_class.new.convert(magento_customer, {})

        expect(shopify_customer).to include('accepts_marketing' => 'false')
      end

      it 'sets accepts_marketing to nil if is_subscribed is nil in the magento customer input' do
        magento_customer = FactoryBot.build(:magento_customer, is_subscribed: nil)
        shopify_customer = described_class.new.convert(magento_customer, {})

        expect(shopify_customer).to include('accepts_marketing' => nil)
      end
    end
  end
end
