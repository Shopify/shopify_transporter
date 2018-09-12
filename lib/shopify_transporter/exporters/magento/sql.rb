# frozen_string_literal: true
require 'sequel'

module ShopifyTransporter
  module Exporters
    module Magento
      class SQL
        def initialize(
          database: '',
          hostname: '',
          port: 3306,
          username: '',
          password: ''
        )

          @database = database
          @hostname = hostname
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
