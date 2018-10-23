# frozen_string_literal: true
require 'shopify_transporter/pipeline/magento/product/variant_attributes'

module ShopifyTransporter::Pipeline::Magento::Product
  RSpec.describe VariantAttributes, type: :helper do

    context '#convert' do
      it 'should accumulate variants of child products and append them to corresponding parent product' do
        parent_product = FactoryBot.build(:configurable_magento_product)
        child_product = FactoryBot.build(:simple_magento_product, :with_parent_id)
        shopify_product = described_class.new.convert(child_product, parent_product)

        expected_shopify_product = {
          product_id: '1',
          title: 'French Cuff Cotton Twill Oxford',
          body_html: 'French Cuff Cotton Twill Oxford',
          handle: 'french-cuff-cotton-twill-oxford',
          created_at: '2013-03-05T01:25:10-05:00',
          published_scope: 'web',
          variants: [
              {
                  type: 'simple',
                  product_id: '2',
                  title: 'French Cuff Cotton Twill Oxford',
                  body_html: 'Button front. Long sleeves. Tapered collar, chest pocket, french cuffs.',
                  handle: 'french-cuff-cotton-twill-oxford',
                  created_at: '2013-03-05T01:25:10-05:00',
                  published_scope: 'web',
                  parent_id: '1'
              }
          ]
        }
        expect(shopify_product).to eq(expected_shopify_product.deep_stringify_keys)
      end

    end
  end
end
