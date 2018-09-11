# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe OrderExporter do
        context '#run' do
          it 'retrieves orders from Magento using the SOAP API and returns the results' do
            soap_client = double("soap client")

            sales_order_list_response_body = double('sales_order_list_response_body')
            sales_order_info_response_body = double('sales_order_info_response_body')

            expect(soap_client)
              .to receive(:call).with(:sales_order_list, anything)
              .and_return(sales_order_list_response_body)
              .at_least(:once)

            expect(sales_order_list_response_body).to receive(:body).and_return(
              sales_order_list_response: {
                result: {
                  item: [
                    {
                      increment_id: '12345',
                      top_level_attribute: "an_attribute",
                    },
                  ],
                },
              },
            ).at_least(:once)

            expect(soap_client)
              .to receive(:call).with(:sales_order_info, order_increment_id: '12345')
              .and_return(sales_order_info_response_body)
              .at_least(:once)

            expect(sales_order_info_response_body).to receive(:body).and_return(
              sales_order_info_response: {
                result: {
                  order_info_attribute: "another_attribute",
                },
              },
            ).at_least(:once)

            expected_result = [
              {
                increment_id: '12345',
                top_level_attribute: "an_attribute",
                items: {
                  order_info_attribute: "another_attribute",
                },
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
