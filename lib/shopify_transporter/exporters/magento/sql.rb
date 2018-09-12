# frozen_string_literal: true

require 'sequel'
require 'json'

module ShopifyTransporter
  module Exporters
    module Magento
      class SQL
        def initialize(
          database: '',
          host: '',
          port: 3306,
          username: '',
          password: '',
        )

          @database = database
          @host = host
          @port = port
          @username = username
          @password = password
        end

        def connect
          Sequel.connect(
            adapter: :mysql2,
            user: @username,
            password: @password,
            host: @host,
            port: @port,
            database: @database
          )
        end
      end
    end
  end
end
