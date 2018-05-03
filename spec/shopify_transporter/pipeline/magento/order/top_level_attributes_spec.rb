# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/order/top_level_attributes'

module ShopifyTransporter::Pipeline::Magento::Order
  RSpec.describe TopLevelAttributes, type: :helper do
    context '#convert' do
      it 'extracts top level shopify order attributes from an input hash' do
        magento_order = FactoryBot.build(:magento_order,
          increment_id: 'test order number',
          created_at: 'test created at',
          subtotal: 'test subtotal',
          tax_amount: 'test tax amount',
          grand_total: 'test grand total',
          customer_email: 'test customer email',
          customer_firstname: 'test customer firstname',
          customer_lastname: 'test customer lastname',
        )
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order = {
          name: 'test order number',
          processed_at: 'test created at',
          subtotal_price: 'test subtotal',
          total_tax: 'test tax amount',
          total_price: 'test grand total',
          customer: {
            email: 'test customer email',
            first_name: 'test customer firstname',
            last_name: 'test customer lastname',
          }
        }

        expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
      end
    end
  end
end
