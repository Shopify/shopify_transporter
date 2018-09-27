# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/product/top_level_attributes'

module ShopifyTransporter::Pipeline::Magento::Product
  RSpec.describe TopLevelAttributes, type: :helper do
    context '#convert' do
      it 'extracts top level shopify product attributes from an input hash' do
        magento_product = FactoryBot.build(:magento_product)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_shopify_product = {
          title: magento_product['name'],
          body_html: magento_product['description'],
          handle: magento_product['url_key'],
          published: false,
          published_at: '',
          published_scope: '',
        }

        expect(shopify_product.deep_stringify_keys).to eq(expected_shopify_product.deep_stringify_keys)
      end

      it 'should handle published scope properly' do
        magento_product = FactoryBot.build(:published_magento_product)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_shopify_product_published_scope = {
          published: true,
          published_at: magento_product['updated_at'],
          published_scope: "global",
        }

        expect(shopify_product.deep_stringify_keys).to include(expected_shopify_product_published_scope.deep_stringify_keys)
      end

      it 'ignores attributes that are not explicitly specified in the top-level' do
        with_nonsense = {
          nonsense_value: :blah,
          nonsense_key: :foo,
          nonsense_namespace: :bar,
        }
        magento_product = FactoryBot.build(:magento_product, with_nonsense)
        shopify_product = described_class.new.convert(magento_product, {})
        expect(shopify_product.deep_stringify_keys).to_not include(with_nonsense.deep_stringify_keys)
      end

      it 'should handle product tags conversion' do
        magento_product = FactoryBot.build(:magento_product, :with_product_tags)
        shopify_product = described_class.new.convert(magento_product, {})
        expected_product_tag_info = {
          tags: 'white, shirt'
        }
        expect(shopify_product.deep_stringify_keys).to include(expected_product_tag_info.deep_stringify_keys)
      end

      context '#images' do
        it 'handles images with no labels' do
          magento_product = FactoryBot.build(:magento_product, :with_no_label_image)
          shopify_product = described_class.new.convert(magento_product, {})
          expected_shopify_product_image = {
            images: [
              {
                src: :src_value,
                position: 1,
              }
            ]
          }

          expect(shopify_product.deep_stringify_keys).to include(expected_shopify_product_image.deep_stringify_keys)
        end

        it 'handles images with labels' do
          magento_product = FactoryBot.build(:magento_product, :with_label_image)
          shopify_product = described_class.new.convert(magento_product, {})
          expected_shopify_product_image = {
            images: [
              {
                src: :src_value2,
                position: 2,
                alt: 'alt_text',
              }
            ]
          }

          expect(shopify_product.deep_stringify_keys).to include(expected_shopify_product_image.deep_stringify_keys)
        end
      end
    end
  end
end
