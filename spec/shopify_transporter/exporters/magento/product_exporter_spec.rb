# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe ProductExporter do
        context '#run' do
          it 'retrieves simple products from Magento using the SOAP API and returns the results' do
            soap_client = double("soap client")

            catalog_product_list_response_body = double('catalog_product_list_response_body')
            catalog_product_info_response_body = double('catalog_product_info_response_body')

            expect(soap_client)
              .to receive(:call).with(:catalog_product_list, anything)
              .and_return(catalog_product_list_response_body)
              .at_least(:once)

            expect(catalog_product_list_response_body).to receive(:body).and_return(
              catalog_product_list_response: {
                store_view: {
                  item: [
                    {
                      product_id: '12345',
                      type: 'simple',
                      top_level_attribute: "an_attribute",
                    },
                  ],
                },
              },
            ).at_least(:once)

            expected_result = [
              {
                product_id: '12345',
                type: 'simple',
                top_level_attribute: "an_attribute",
              },
            ]

            exporter = described_class.new(store_id: 1, client: soap_client)
            expect(exporter.export).to eq(expected_result)
          end

          it 'retrieves configurable products from Magento using the SOAP API and injects simple product ids' do
            soap_client = double("soap client")

            catalog_product_list_response_body = double('catalog_product_list_response_body')
            catalog_product_info_response_body = double('catalog_product_info_response_body')

            expect(soap_client)
              .to receive(:call).with(:catalog_product_list, anything)
              .and_return(catalog_product_list_response_body)
              .at_least(:once)

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
            ).at_least(:once)

            expected_result = [
              {
                product_id: '12345',
                top_level_attribute: "an_attribute",
                type: 'configurable',
                simple_product_ids: ['800', '801', '802'],
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
              exporter = described_class.new(store_id: 1, client: soap_client)
              expect(exporter.export).to eq(expected_result)
            end
          end
        end
      end
    end
  end
end
