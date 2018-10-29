# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/order/top_level_attributes'

module ShopifyTransporter::Pipeline::Magento::Order
  RSpec.describe ShippingLines, type: :helper do
    context '#convert' do
      it "extract shipping info into correct shipping lines in Shopify" do
        magento_order = FactoryBot.build(:magento_order, :with_shipping_info)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shipping_lines = [
          {
            code: magento_order['shipping_description'],
            title: magento_order['shipping_description'],
            price: magento_order['shipping_amount'],
            carrier_identifier: magento_order['shipping_method'],
            tax_lines: [
              {
                price: magento_order['shipping_tax_amount']
              }.stringify_keys
            ]
          }.stringify_keys
        ]
        expect(shopify_order['shipping_lines']).to eq(expected_shipping_lines)
      end
    end
  end
end