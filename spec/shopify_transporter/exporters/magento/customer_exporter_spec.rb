# frozen_string_literal: true

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe CustomerExporter do
        context '#key' do
          it 'returns :customer_id' do
            expect(described_class.new.key).to eq(:customer_id)
          end
        end

        describe '#export' do
          it 'retrieves customers from Magento using the SOAP API and returns the results' do
            soap_client = double("soap client")

            customer_customer_list_response_body = double('customer_customer_list_response_body')
            customer_address_list_response_body = double('customer_address_list_response_body')

            expect(soap_client)
              .to receive(:call_in_batches)
              .with(
                method: :customer_customer_list,
                batch_index_column: 'customer_id',
              )
              .and_return([customer_customer_list_response_body]).at_least(:once)

            expect(customer_customer_list_response_body).to receive(:body).and_return(
              customer_customer_list_response: {
                store_view: {
                  item: {
                    customer_id: '654321',
                    top_level_attribute: "an_attribute",
                  },
                },
              },
            ).at_least(:once)

            expect(soap_client)
              .to receive(:call)
              .with(:customer_address_list, customer_id: '654321')
              .and_return(customer_address_list_response_body).at_least(:once)

            expect(customer_address_list_response_body).to receive(:body).and_return(
              customer_address_list_response: {
                result: {
                  item: {
                    customer_address_attribute: "another_attribute",
                  }
                },
              },
            ).at_least(:once)

            expected_result =  {
              customer_id: '654321',
              top_level_attribute: "an_attribute",
              address_list: {
                customer_address_list_response: {
                  result: {
                    item: {
                      customer_address_attribute: "another_attribute",
                    }
                  }
                },
              },
            }

            exporter = described_class.new(soap_client: soap_client)
            expect { |block| exporter.export(&block) }.to yield_with_args(expected_result)
          end

          it 'works with multiple customers' do
            soap_client = double("soap client")

            customer_customer_list_response_body = double('customer_customer_list_response_body')
            customer_address_list_response_body = double('customer_address_list_response_body')

            expect(soap_client)
              .to receive(:call_in_batches)
              .with(
                method: :customer_customer_list,
                batch_index_column: 'customer_id',
              )
              .and_return([customer_customer_list_response_body]).at_least(:once)

            expect(customer_customer_list_response_body).to receive(:body).and_return(
              customer_customer_list_response: {
                store_view: {
                  item: [
                    {
                      customer_id: '10',
                      top_level_attribute: 'customer1',
                    },
                    {
                      customer_id: '11',
                      top_level_attribute: 'customer2',
                    },
                  ]
                },
              },
            ).at_least(:once)

            expect(soap_client)
              .to receive(:call)
              .with(:customer_address_list, customer_id: '10')
              .and_return(customer_address_list_response_body)

            expect(soap_client)
              .to receive(:call)
              .with(:customer_address_list, customer_id: '11')
              .and_return(customer_address_list_response_body)

            allow(customer_address_list_response_body).to receive(:body).and_return(
              customer_address_list_response: {
                result: {
                  item: {
                    customer_address_attribute: 'another_attribute',
                  }
                },
              },
            ).at_least(:once)

            expected_result =  [
              {
                customer_id: '10',
                top_level_attribute: 'customer1',
                address_list: {
                  customer_address_list_response: {
                    result: {
                      item: {
                        customer_address_attribute: 'another_attribute',
                      }
                    }
                  },
                },
              },
              {
                customer_id: '11',
                top_level_attribute: 'customer2',
                address_list: {
                  customer_address_list_response: {
                    result: {
                      item: {
                        customer_address_attribute: 'another_attribute',
                      }
                    }
                  },
                },
              }
            ]

            exporter = described_class.new(soap_client: soap_client)
            expect { |block| exporter.export(&block) }.to yield_successive_args(*expected_result)

          end
        end
      end
    end
  end
end
