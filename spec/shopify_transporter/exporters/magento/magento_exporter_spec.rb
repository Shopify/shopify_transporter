# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'

RSpec.describe ShopifyTransporter::Exporters::Magento::MagentoExporter do
  context '#for' do
    let(:fake_client) { double('fake_client') }

    it 'returns CustomerExporter for customer type' do
      expect(ShopifyTransporter::Exporters::Magento::MagentoExporter.for('customer', 1, fake_client))
        .to be_a(ShopifyTransporter::Exporters::Magento::CustomerExporter)
    end

    it 'returns OrderExporter for order type' do
      expect(ShopifyTransporter::Exporters::Magento::MagentoExporter.for('order', 1, fake_client))
        .to be_a(ShopifyTransporter::Exporters::Magento::OrderExporter)
    end

    it 'raises for any other type' do
      expect { ShopifyTransporter::Exporters::Magento::MagentoExporter.for('nonexistent_type', 1, fake_client) }
        .to raise_error(ShopifyTransporter::Exporters::Magento::MissingExporterError)
    end
  end
end
