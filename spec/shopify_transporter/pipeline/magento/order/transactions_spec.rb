# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/order/top_level_attributes'

module ShopifyTransporter::Pipeline::Magento::Order
  RSpec.describe Transactions, type: :helper do
    context '#convert' do
      it "converts payment into sale transactions successfully" do
        magento_order = FactoryBot.build(:magento_order, total_paid: 1000.5)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_transaction = [
          {
              amount: 1000.5,
              kind: 'sale',
              status: 'success'
          }.stringify_keys
        ]
        expect(shopify_order['transactions']).to eq(expected_transaction)
      end

      it "converts refund into refund transactions successfully" do
        magento_order = FactoryBot.build(:magento_order, total_refunded: 100)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_transaction = [
          {
            amount: 100,
            kind: 'refund',
            status: 'success'
          }.stringify_keys
        ]
        expect(shopify_order['transactions']).to eq(expected_transaction)
      end
    end
  end
end
