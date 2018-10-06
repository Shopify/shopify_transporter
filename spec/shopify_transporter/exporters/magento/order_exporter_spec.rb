# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe OrderExporter do
        context '#key' do
          it 'returns :order_id' do
            expect(described_class.new.key).to eq(:order_id)
          end
        end

        describe '#export' do
          it 'retrieves orders from Magento using the SOAP API and returns the results' do
            soap_client = double("soap client")

            sales_order_list_response_body = double('sales_order_list_response_body')
            sales_order_info_response_body = double('sales_order_info_response_body')

            expect(soap_client)
              .to receive(:call_in_batches)
              .with(
                method: :sales_order_list,
                batch_index_column: 'order_id',
              )
              .and_return([sales_order_list_response_body])
              .at_least(:once)

            expect(sales_order_list_response_body).to receive(:body).and_return(
              sales_order_list_response: {
                result: {
                  item: {
                    increment_id: '12345',
                    top_level_attribute: "an_attribute",
                  },
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

            expected_result = {
              increment_id: '12345',
              top_level_attribute: "an_attribute",
              items: {
                result: {
                  order_info_attribute: "another_attribute",
                }
              },
            }

            exporter = described_class.new(soap_client: soap_client)
            expect { |block| exporter.export(&block) }.to yield_with_args(expected_result)
          end

          it 'works with multiple orders being returned by the soap call' do
            soap_client = double('soap client')

            sales_order_list_response_body = double('sales_order_list_response_body')
            sales_order_info_response_body = double('sales_order_info_response_body')

            expect(soap_client)
              .to receive(:call_in_batches)
              .with(
                method: :sales_order_list,
                batch_index_column: 'order_id',
              )
              .and_return([sales_order_list_response_body])
              .at_least(:once)

            expect(sales_order_list_response_body).to receive(:body).and_return(
              sales_order_list_response: {
                result: {
                  item: [
                    {
                      increment_id: '10',
                      top_level_attribute: 'order1',
                    },
                    {
                      increment_id: '11',
                      top_level_attribute: 'order2',
                    },
                  ]
                },
              },
            ).at_least(:once)

            expect(soap_client)
              .to receive(:call).with(:sales_order_info, order_increment_id: '10')
              .and_return(sales_order_info_response_body)
            expect(soap_client)
              .to receive(:call).with(:sales_order_info, order_increment_id: '11')
              .and_return(sales_order_info_response_body)

            allow(sales_order_info_response_body).to receive(:body).and_return(
              sales_order_info_response: {
                result: {
                  order_info_attribute: 'info',
                },
              },
            )

            expected_result = [
              {
                increment_id: '10',
                top_level_attribute: 'order1',
                items: {
                  result: {
                    order_info_attribute: 'info',
                  }
                },
              },
              {
                increment_id: '11',
                top_level_attribute: 'order2',
                items: {
                  result: {
                    order_info_attribute: 'info',
                  }
                },
              },
            ]

            exporter = described_class.new(soap_client: soap_client)
            expect { |block| exporter.export(&block) }.to yield_successive_args(*expected_result)
          end

          context 'when order details are unretrievable' do
            it 'skips the current order' do
              soap_client = double('soap client')

              sales_order_list_response_body = double('sales_order_list_response_body')
              sales_order_info_response_body = double('sales_order_info_response_body')
              expect(soap_client)
                .to receive(:call_in_batches)
                .with(
                  method: :sales_order_list,
                  batch_index_column: 'order_id',
                )
                .and_return([sales_order_list_response_body])
                .at_least(:once)

              expect(sales_order_list_response_body).to receive(:body).and_return(
                sales_order_list_response: {
                  result: {
                    item: [
                      {
                        increment_id: '10',
                        order_id: '10',
                        top_level_attribute: 'order1',
                      },
                    ]
                  },
                },
              ).at_least(:once)

              expect(soap_client)
                .to receive(:call).with(:sales_order_info, order_increment_id: '10')
                .and_raise(Savon::Error)

              allow(sales_order_info_response_body).to receive(:body).and_return(
                sales_order_info_response: {
                  result: {
                    order_info_attribute: 'info',
                  },
                },
              )

              expected_result = {
                increment_id: '10',
                order_id: '10',
                top_level_attribute: 'order1',
              }

              exporter = described_class.new(soap_client: soap_client)
              expect do |block|
                stderr = capture(:stderr) { exporter.export(&block) }
                output = <<~WARNING
                  ***
                  Warning:
                  Encountered an error with fetching details for order with id: 10
                  {
                    "increment_id": "10",
                    "order_id": "10",
                    "top_level_attribute": "order1"
                  }
                  The exact error was:
                  Savon::Error: 
                  Savon::Error
                  -
                  Exporting the order (10) without its details.
                  Continuing with the next order.
                  ***
                WARNING
                expect(stderr).to eq(output)
              end.to yield_with_args(expected_result)
            end
          end
        end
      end
    end
  end
end
