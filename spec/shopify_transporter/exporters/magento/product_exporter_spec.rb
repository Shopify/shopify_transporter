# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe ProductExporter do
        context '#run' do
          it 'retrieves products from Magento using the SOAP API and returns the results' do
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
                      product_id: 12345,
                      top_level_attribute: "an_attribute",
                    },
                  ],
                },
              },
            ).at_least(:once)

            expected_result = [
              {
                product_id: 12345,
                top_level_attribute: "an_attribute",
              },
            ]

            exporter = described_class.new(store_id: 1, client: soap_client)
            expect(exporter.export).to eq(expected_result)
          end
        end
      end
    end
  end
end
