# frozen_string_literal: true
require 'csv'
require 'sequel'

module ShopifyTransporter
  module Exporters
    module Magento
      class DatabaseCache
        DB_CACHE_FOLDER = './cache/magento_db'

        def initialize
          @cache = {}
        end

        def table(table_name)
          @cache[table_name] ||= CSV.read("#{DB_CACHE_FOLDER}/#{table_name}.csv", headers: true)
        end
      end
    end
  end
end
