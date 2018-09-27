# frozen_string_literal: true
require 'shopify_transporter/exporters/magento/product_options'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe ProductOptions do
        let(:database_table_exporter) { double('database_table_exporter') }
        let(:database_cache) { double('database_cache') }
        let(:product_options) { described_class.new(database_table_exporter, database_cache) }

        before :each do
          allow(database_table_exporter).to receive(:export_table).with(
            'catalog_product_super_attribute',
            'product_super_attribute_id'
          )
          allow(database_table_exporter).to receive(:export_table).with(
            'catalog_product_super_attribute_label',
            'value_id'
          )
          allow(database_table_exporter).to receive(:export_table).with(
            'eav_attribute_option_value',
            'value_id'
          )

          allow(database_cache).to receive(:table).with('catalog_product_super_attribute').and_return(
            [
              {
                'product_super_attribute_id' => '13',
                'product_id' => '402',
                'attribute_id' => '92',
                'position' => '0',
              },
              {
                'product_super_attribute_id' => '14',
                'product_id' => '402',
                'attribute_id' => '180',
                'position' => '0',
              },
              {
                'product_super_attribute_id' => '15',
                'product_id' => '403',
                'attribute_id' => '92',
                'position' => '0',
              }
            ]
          )

          allow(database_cache).to receive(:table).with('catalog_product_super_attribute_label').and_return(
            [
              {
                'value_id' => '13',
                'product_super_attribute_id' => '13',
                'store_id' => '0',
                'use_default' => '1',
                'value' => 'Color',
              },
              {
                'value_id' => '14',
                'product_super_attribute_id' => '14',
                'store_id' => '0',
                'use_default' => '1',
                'value' => 'Size',
              },
              {
                'value_id' => '15',
                'product_super_attribute_id' => '15',
                'store_id' => '0',
                'use_default' => '1',
                'value' => 'Color',
              }
            ]
          )

          allow(database_cache).to receive(:table).with('eav_attribute_option_value').and_return(
            [
              {
                'value_id' => '2046',
                'option_id' => '22',
                'store_id' => '0',
                'value' => 'White',
              },
              {
                'value_id' => '20467',
                'option_id' => '22',
                'store_id' => '1',
                'value' => 'White',
              },
              {
                'value_id' => '2116',
                'option_id' => '81',
                'store_id' => '0',
                'value' => 'XS',
              },
              {
                'value_id' => '2116',
                'option_id' => '81',
                'store_id' => '1',
                'value' => 'XS',
              },
              {
                'value_id' => '1246',
                'option_id' => '91',
                'store_id' => '0',
                'value' => 'Scratch Resistant',
              }
            ]
          )
        end

        it 'extracts product tables on initialization' do
          expect(database_table_exporter).to receive(:export_table).with(
            'catalog_product_super_attribute',
            'product_super_attribute_id'
          )
          expect(database_table_exporter).to receive(:export_table).with(
            'catalog_product_super_attribute_label',
            'value_id'
          )
          expect(database_table_exporter).to receive(:export_table).with(
            'eav_attribute_option_value',
            'value_id'
          )

          described_class.new(database_table_exporter, database_cache)
        end

        describe 'product options' do
          it '#option_names_for_soap returns option names in lower case' do
            expect(product_options.option_names_for_soap('402')).to eq(%w(color size))
          end

          it '#option_names_for_soap returns an empty array if the options were not found' do
            expect(product_options.option_names_for_soap('1999')).to eq([])
          end

          it '#shopify_option_names returns options in the shopify format based on product id' do
            expect(product_options.shopify_option_names('402')).to eq(
              'option1_name': 'Color',
              'option2_name': 'Size'
            )
          end

          it '#shopify_option_names returns an empty hash if the options were not found' do
            expect(product_options.shopify_option_names('1999')).to eq({})
          end
        end

        describe '#shopify_variant_options' do
          it '#shopify_variant_options returns the option names and values from a given parent product' \
            ' and attributes hash' do
            simple_product = {
              parent_id: '402',
              additional_attributes: {
                item: [
                  {
                    key: 'color',
                    value: '22',
                  },
                  {
                    key: 'size',
                    value: '81',
                  },
                  {
                    key: 'length',
                    value: nil,
                  },
                ],
              }
            }

            expect(product_options.shopify_variant_options(simple_product))
              .to eq(
                'option1_name': 'Color',
                'option1_value': 'White',
                'option2_name': 'Size',
                'option2_value': 'XS',
              )
          end

          it '#shopify_variant_options does not convert additional attributes into options' do
            simple_product = {
              parent_id: '402',
              additional_attributes: {
                item: [
                  {
                    key: 'length',
                    value: nil,
                  },
                ]
              }
            }

            expect(product_options.shopify_variant_options(simple_product))
              .to eq(
                'option1_name': 'Color',
                'option1_value': nil,
                'option2_name': 'Size',
                'option2_value': nil,
              )
          end

          it '#shopify_variant_options returns nil for options if expected option values are not found' do
            simple_product = {
              parent_id: '402',
              additional_attributes: {
                item: [
                  {
                    key: 'color',
                    value: '22',
                  },
                ],
              }
            }

            expect(product_options.shopify_variant_options(simple_product))
              .to eq(
                'option1_name': 'Color',
                'option1_value': 'White',
                'option2_name': 'Size',
                'option2_value': nil,
              )
          end

          it 'returns an empty hash if the simple product does not have required keys' do
            simple_product = {}

            expect(product_options.shopify_variant_options(simple_product)).to eq({})
          end
        end
      end
    end
  end
end
