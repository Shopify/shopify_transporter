# frozen_string_literal: true
require 'sequel'

module ShopifyTransporter
  module Exporters
    module Magento
      class SQL
        def initialize(
          database: '',
          host: '',
          port: 3306,
          user: '',
          password: ''
        )

          @database = database
          @host = host
          @port = port
          @user = user
          @password = password
        end

        def connect
          @connection ||= Sequel.connect(
            adapter: :mysql2,
            user: @user,
            password: @password,
            host: @host,
            port: @port,
            database: @database
          )
          yield(@connection)
          @connection.disconnect
        end
      end
    end
  end
end
