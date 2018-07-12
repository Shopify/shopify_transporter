# frozen_string_literal: true
require 'bundler/setup'
Bundler.require(:test)

require_relative '../../../../../../sample_scripts/third_party_platform_exporting/magento/v1.9/soap_api/orders.rb'

RSpec.describe OrderExporter do
  context '#run' do
    it 'works' do
      soap_client = double("soap client")

      login_response_body = double('login_response_body')
      sales_order_list_response_body = double('sales_order_list_response_body')
      sales_order_info_response_body = double('sales_order_info_response_body')

      expect(soap_client).to receive(:call).with(:login, anything).and_return(login_response_body).exactly(:once)
      expect(login_response_body).to receive(:body).and_return(
        {
          login_response: {
            login_return: 12345
          }
        }
      ).exactly(:once)

      expect(soap_client).to receive(:call).with(:sales_order_list, anything).and_return(sales_order_list_response_body).at_least(:once)
      expect(sales_order_list_response_body).to receive(:body).and_return(
        {
          sales_order_list_response: {
            result: {
              item: {
                stuff: "blah"
              }
            }
          }
        }
      ).at_least(:once)

      expect(soap_client).to receive(:call).with(:sales_order_info, anything).and_return(sales_order_info_response_body).at_least(:once)
      expect(sales_order_info_response_body).to receive(:body).and_return(
        {
          sales_order_info_response: {
            some_detail: "yep for sure"
          }
        }
      ).at_least(:once)

      allow_any_instance_of(TransporterExporter).to receive(:soap_client).and_return(soap_client)

      expect { subject.run }.not_to raise_error
    end
  end
end
