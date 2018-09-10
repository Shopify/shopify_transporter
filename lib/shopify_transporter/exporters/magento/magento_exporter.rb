# frozen_string_literal: true

require_relative './customer_exporter.rb'
require_relative './order_exporter.rb'

module ShopifyTransporter
  module Exporters
    module Magento
      class MissingExporterError < ExportError; end

      class MagentoExporter
        def self.for(type: nil, store_id: nil, client: nil)
          case type
          when 'customer'
            CustomerExporter
          when 'order'
            OrderExporter
          else
            raise MissingExporterError
          end.new(store_id: store_id, client: client)
        end
      end
    end
  end
end
