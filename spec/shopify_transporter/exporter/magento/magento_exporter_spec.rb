# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

RSpec.describe ShopifyTransporter::MagentoExporter do
  context '#for' do
    let(:fake_client) { double('fake_client') }

    it 'returns MagentoCustomerExporter for customer type' do
      expect(ShopifyTransporter::MagentoExporter.for('customer', 1, fake_client))
        .to be_a(ShopifyTransporter::MagentoCustomerExporter)
    end

    it 'returns MagentoOrderExporter for order type' do
      expect(ShopifyTransporter::MagentoExporter.for('order', 1, fake_client))
        .to be_a(ShopifyTransporter::MagentoOrderExporter)
    end

    it 'raises for any other type' do
      expect { ShopifyTransporter::MagentoExporter.for('nonexistent_type', 1, fake_client) }
        .to raise_error(ShopifyTransporter::MagentoExporter::MissingMagentoExporterError)
    end
  end
end
