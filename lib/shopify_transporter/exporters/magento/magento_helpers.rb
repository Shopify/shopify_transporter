# frozen_string_literal: true
require 'sequel'
require 'English'

module ShopifyTransporter
  module Exporters
    module Magento
      module MagentoHelpers
        BATCH_SIZE = 1000

        def in_batches(table, batch_field_key)
          current_id = table.first[batch_field_key]
          max_id = table.last[batch_field_key]

          while current_id <= max_id
            batch = table.where(batch_field_key => current_id...(current_id + BATCH_SIZE))
            yield batch
            current_id += BATCH_SIZE
          end
        end
      end
    end
  end
end
