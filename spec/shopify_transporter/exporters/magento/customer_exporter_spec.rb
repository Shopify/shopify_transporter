# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

RSpec.describe ShopifyTransporter::Exporters::Magento::CustomerExporter do
  context '#run' do
    it 'retrieves customers from Magento using the SOAP API and returns the results' do
      soap_client = double("soap client")

      customer_customer_list_response_body = double('customer_customer_list_response_body')
      customer_address_list_response_body = double('customer_address_list_response_body')

      expect(soap_client)
        .to receive(:call)
        .with(:customer_customer_list, anything)
        .and_return(customer_customer_list_response_body).at_least(:once)

      expect(customer_customer_list_response_body).to receive(:body).and_return(
        customer_customer_list_response: {
          store_view: {
            item: [
              {
                customer_id: 654321,
                top_level_attribute: "an_attribute",
              },
            ],
          },
        },
      ).at_least(:once)

      expect(soap_client)
        .to receive(:call)
        .with(:customer_address_list, customer_id: 654321)
        .and_return(customer_address_list_response_body).at_least(:once)

      expect(customer_address_list_response_body).to receive(:body).and_return(
        customer_address_list_response: {
          result: {
            customer_address_attribute: "another_attribute",
          },
        },
      ).at_least(:once)

      expected_result = [
        {
          customer_id: 654321,
          top_level_attribute: "an_attribute",
          address_list: {
            customer_address_attribute: "another_attribute",
          },
        },
      ]

      exporter = described_class.new(store_id: 1, client: soap_client)
      expect(exporter.export).to eq(expected_result)
    end
  end
end
