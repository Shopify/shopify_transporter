# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/order/top_level_attributes'

module ShopifyTransporter::Pipeline::Magento::Order
  RSpec.describe Discounts, type: :helper do
    context '#convert' do
      it "extract fixed amount discount into correct discount codes in Shopify" do
        magento_order = FactoryBot.build(:magento_order, :with_fixed_amount_discount)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_discount_code = [
          {
            amount: 15,
            code: magento_order['discount_description'],
            type: 'fixed_amount'
          }.stringify_keys
        ]
        expect(shopify_order['discounts']).to eq(expected_discount_code)
      end

      it "extract shipping discount into correct discount codes in Shopify" do
        magento_order = FactoryBot.build(:magento_order, :with_shipping_discount)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_discount_code = [
          {
            amount: 15,
            code: magento_order['discount_description'],
            type: 'shipping'
          }.stringify_keys
        ]
        expect(shopify_order['discounts']).to eq(expected_discount_code)
      end

      it "extract percentage discount into correct discount codes in Shopify" do
        magento_order = FactoryBot.build(:magento_order, :with_percentage_discount)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_discount_code = [
          {
            amount: 25,
            code: magento_order['discount_description'],
            type: 'percentage'
          }.stringify_keys
        ]
        expect(shopify_order['discounts']).to eq(expected_discount_code)
      end

      it "extract percentage discount into correct discount codes in Shopify when there're multiple line items" do
        magento_order = FactoryBot.build(:magento_order, :with_percentage_discounts)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_discount_code = [
          {
            amount: 25,
            code: magento_order['discount_description'],
            type: 'percentage'
          }.stringify_keys
        ]
        expect(shopify_order['discounts']).to eq(expected_discount_code)
      end

      it "will not extract shipping discount if the discount amount is less than shipping fee" do
        magento_order = FactoryBot.build(:magento_order, :with_disqualified_shipping_discount)
        shopify_order = described_class.new.convert(magento_order, {})
        expect(shopify_order['discounts']).to eq([])
      end

      it "will not identify discount as percentage discount if any line item has a different percentage applied" do
        magento_order = FactoryBot.build(:magento_order, :with_disqualified_percentage_discount)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_discount_code = [
          {
            amount: 15,
            code: magento_order['discount_description'],
            type: 'fixed_amount'
          }.stringify_keys
        ]
        expect(shopify_order['discounts']).to eq(expected_discount_code)
      end

      it 'should generate a list of discount codes when there are more than one discount applied' do
        magento_order = FactoryBot.build(:magento_order, :with_percentage_discount, :with_shipping_discount)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_discount_code = [
          {
            amount: 25,
            code: magento_order['discount_description'],
            type: 'percentage'
          }.stringify_keys,
          {
            amount: 15,
            code: magento_order['discount_description'],
            type: 'shipping'
          }.stringify_keys
        ]
        expect(shopify_order['discounts']).to match_array(expected_discount_code)
      end

      it 'should generate default code when there are no such info in the input' do
        magento_order = FactoryBot.build(:magento_order, :with_percentage_discount)
        magento_order['discount_description'] = nil
        shopify_order = described_class.new.convert(magento_order, {})
        expected_discount_code = [
          {
            amount: 25,
            code: 'Magento',
            type: 'percentage'
          }.stringify_keys
        ]
        expect(shopify_order['discounts']).to match_array(expected_discount_code)
      end
    end
  end
end
