# frozen_string_literal: true
require 'bundler/setup'
Bundler.require(:test)

require_relative '../../../../../../sample_scripts/third_party_platform_exporting/magento/v1.9/soap_api/orders.rb'

RSpec.describe OrderExporter do
  context '#run' do
    it 'does things' do
      soap_client = double("soap client")
      allow_any_instance_of(TransporterExporter).to receive(:soap_client).and_return(soap_client)

      expect { subject.run }.not_to raise_error
    end
  end
end
