# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe MagentoExporter do
        context '#for' do
          let(:fake_client) { double('fake_client') }
          let(:fake_adapter) { double('fake_adapter') }

          it 'returns CustomerExporter for customer type' do
            expect(described_class.for(type: 'customer'))
              .to be(Magento::CustomerExporter)
          end

          it 'returns OrderExporter for order type' do
            expect(described_class.for(type: 'order'))
              .to be(Magento::OrderExporter)
          end

          it 'returns ProductExporter for product type' do
            expect(described_class.for(type: 'product'))
              .to be(Magento::ProductExporter)
          end

          it 'raises for any other type' do
            expect { described_class.for(type: 'nonexistent_type') }
              .to raise_error(MissingExporterError)
          end
        end
      end
    end
  end
end
