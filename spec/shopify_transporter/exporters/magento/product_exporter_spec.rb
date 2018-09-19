# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe ProductExporter do
        context '#run'
          it 'retrieves configurable products from Magento using the SOAP API and returns the results' do
            soap_client = double("soap client")

            catalog_product_list_response_body = double('catalog_product_list_response_body')
            catalog_product_info_response_body = double('catalog_product_info_response_body')

            expect(soap_client)
              .to receive(:call).with(:catalog_product_list, anything)
              .and_return(catalog_product_list_response_body)


            expect(catalog_product_list_response_body).to receive(:body).and_return(
              catalog_product_list_response: {
                store_view: {
                  item: [
                    {
                      product_id: '12345',
                      type: 'configurable',
                      top_level_attribute: "an_attribute",
                    },
                  ],
                },
              },
            )

            expect(soap_client)
              .to receive(:call).with(:catalog_product_info, product_id: '12345')
              .and_return(catalog_product_info_response_body)

            expect(catalog_product_info_response_body).to receive(:body).and_return(
              catalog_product_info_response: {
                info: {
                  "attribute_key": "another_attribute"
                }
              }
            )

            expected_result = [
              {
                product_id: '12345',
                type: 'configurable',
                top_level_attribute: "an_attribute",
                attribute_key: "another_attribute",
              },
            ]

            exporter = described_class.new(store_id: 1, soap_client: soap_client)
            expect(exporter.export).to eq(expected_result)
          end

          context '#parent_id' do
            let(:soap_client) { double("soap client") }
            let(:product_mapping_exporter) { double("product_mapping_exporter") }

            let(:catalog_product_list_response_body) { double('catalog_product_list_response_body') }
            let(:catalog_product_info_response_body) { double('catalog_product_info_response_body') }
            it 'retrieves simple products from Magento using the SOAP API and injects parent_id' do
              expect(soap_client)
                .to receive(:call).with(:catalog_product_list, anything)
                .and_return(catalog_product_list_response_body)


              expect(ProductMappingExporter).to receive(:new).and_return(product_mapping_exporter)
              expect(product_mapping_exporter).to receive(:write_mappings)

              expect(catalog_product_list_response_body).to receive(:body).and_return(
                catalog_product_list_response: {
                  store_view: {
                    item: [
                      {
                        product_id: '801',
                        type: 'simple',
                        top_level_attribute: "an_attribute",
                      },
                    ],
                  },
                },
              ).at_least(:once)

              expect(soap_client)
                .to receive(:call).with(:catalog_product_info, product_id: '801')
                .and_return(catalog_product_info_response_body)

              expect(catalog_product_info_response_body).to receive(:body).and_return(
                  catalog_product_info_response: {
                    info: {
                      "attribute_key": "another_attribute"
                    }
                  }
              ).at_least(:once)
              expected_result = [
                {
                  product_id: '801',
                  top_level_attribute: "an_attribute",
                  type: 'simple',
                  parent_id: '12345',
                  attribute_key: "another_attribute",
                },
              ]

              mappings = <<~EOS
                product_id,associated_product_id
                12345,800
                12345,801
                12345,802
                67890,900
                67890,901
              EOS

              in_temp_folder do
                File.open('magento_product_mappings.csv', 'w') { |file| file.write(mappings) }
                exporter = described_class.new(store_id: 1, soap_client: soap_client, database_adapter: nil)
                expect(exporter.export).to eq(expected_result)
              end
            end

            it 'retrieves simple products from Magento and does not inject parent_id if the parent_id does not exist' do
              expect(soap_client)
                .to receive(:call).with(:catalog_product_list, anything)
                .and_return(catalog_product_list_response_body)

              expect(soap_client)
                  .to receive(:call).with(:catalog_product_info, product_id: '801')
                          .and_return(catalog_product_info_response_body)

              expect(ProductMappingExporter).to receive(:new).and_return(product_mapping_exporter)
              expect(product_mapping_exporter).to receive(:write_mappings)

              expect(catalog_product_list_response_body).to receive(:body).and_return(
                catalog_product_list_response: {
                  store_view: {
                    item: [
                      {
                        product_id: '801',
                        type: 'simple',
                        top_level_attribute: "an_attribute",
                      },
                    ],
                  },
                },
              ).at_least(:once)

              expect(catalog_product_info_response_body).to receive(:body).and_return(
                  catalog_product_info_response: {
                    info: {
                      "another_key": "another_attribute",
                    },
                  }
              ).at_least(:once)

              expected_result = [
                {
                  product_id: '801',
                  type: 'simple',
                  top_level_attribute: "an_attribute",
                  another_key: "another_attribute",
                },
              ]

              mappings = <<~EOS
                product_id,associated_product_id
                ,800
                ,801
                ,802
                67890,900
                67890,901
              EOS

              in_temp_folder do
                File.open('magento_product_mappings.csv', 'w') { |file| file.write(mappings) }
                exporter = described_class.new(store_id: 1, soap_client: soap_client, database_adapter: nil)
                expect(exporter.export).to eq(expected_result)
              end
            end
          end
        end
    end
  end
end
