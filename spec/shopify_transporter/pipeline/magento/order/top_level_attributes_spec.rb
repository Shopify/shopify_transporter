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
          },
          currency: 'CAD',
          source_name: 'Magento',
          total_discounts: '100',
          total_weight: '40'
        }

        expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
      end

      it 'should attach correct cancelled_at timestamp for a cancelled order' do
        magento_order = FactoryBot.build(:magento_order,
          :with_cancelled_status_history, state: 'canceled')
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order = {
          cancelled_at: '2013-06-18 18:09:08'
        }
        expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
      end

      it 'should attach correct closed_at timestamp for a closed order' do
        magento_order = FactoryBot.build(:magento_order,
          :with_closed_status_history, state: 'closed')
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order = {
          closed_at: '2014-06-18 18:09:08'
        }
        expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
      end

      it 'should handle singular response of qty_shipped' do
        magento_order = FactoryBot.build(:magento_order, :with_qty_shipped_singular)
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order = {
          fulfillment_status: 'fulfilled'
        }
        expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
      end

      it 'should handle singular response of status_history' do
        magento_order = FactoryBot.build(:magento_order, :with_cancelled_status_history, state: 'canceled')
        shopify_order = described_class.new.convert(magento_order, {})
        expected_shopify_order = {
          cancelled_at: '2013-06-18 18:09:08'
        }
        expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
      end


      context "financial_status" do
        it 'financial_status should be paid for a fully paid order' do
          magento_order = FactoryBot.build(:magento_order,
            increment_id: 'test order number',
            grand_total: "1247.6400",
            total_paid: "1247.6400",
            total_refunded: "0"
          )
          shopify_order = described_class.new.convert(magento_order, {})
          expected_shopify_order = {
            name: 'test order number',
            financial_status: 'paid'
          }
          expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
        end

        it 'financial_status should be partially_paid for a partially paid order' do
          magento_order = FactoryBot.build(:magento_order,
            increment_id: 'test order number',
            grand_total: "1247.6400",
            total_paid: "1.000",
            total_refunded: "0"
          )
          shopify_order = described_class.new.convert(magento_order, {})
          expected_shopify_order = {
            name: 'test order number',
            financial_status: 'partially_paid'
          }
          expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
        end

        it 'financial_status should be partially_refunded for a partially refunded order' do
          magento_order = FactoryBot.build(:magento_order,
            increment_id: 'test order number',
            grand_total: "1247.6400",
            total_paid: "1000.000",
            total_refunded: "500.000"
          )
          shopify_order = described_class.new.convert(magento_order, {})
          expected_shopify_order = {
            name: 'test order number',
            financial_status: 'partially_refunded'
          }
          expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
        end

        it 'financial_status should be refunded for a fully refunded order' do
          magento_order = FactoryBot.build(:magento_order,
            increment_id: 'test order number',
            grand_total: "1247.6400",
            total_paid: "1000.000",
            total_refunded: "1000.000"
          )
          shopify_order = described_class.new.convert(magento_order, {})
          expected_shopify_order = {
            name: 'test order number',
            financial_status: 'refunded'
          }
          expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
        end

        it 'financial_status should be pending if the state is Pending Payment' do
          magento_order = FactoryBot.build(:magento_order,
            increment_id: 'test order number',
            state: 'Pending Payment'
          )
          shopify_order = described_class.new.convert(magento_order, {})
          expected_shopify_order = {
            name: 'test order number',
            financial_status: 'pending'
          }
          expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
        end
      end

      context "fulfillment_status" do
        it 'fulfillment_status should be fulfilled for a fully-fulfilled order' do
          magento_order = FactoryBot.build(:magento_order, :with_qty_shipped)
          shopify_order = described_class.new.convert(magento_order, {})
          expected_shopify_order = {
            fulfillment_status: 'fulfilled'
          }
          expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
        end

        it 'fulfillment_status should be partial for a partial-fulfilled order' do
          magento_order = FactoryBot.build(:magento_order, :with_qty_shipped, total_qty_ordered: '3.000')
          shopify_order = described_class.new.convert(magento_order, {})
          expected_shopify_order = {
            fulfillment_status: 'partial'
          }
          expect(shopify_order).to include(expected_shopify_order.deep_stringify_keys)
        end
      end
    end
  end
end
