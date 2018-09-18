# frozen_string_literal: true
require 'sequel'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe SQL do
        context ('#connect') do
          it 'calls Sequel with the right parameters' do
            sql_client = SQL.new(
              database: 'magento',
              host: 'magento-instance.domain.com',
              port: 1234,
              user: 'dbuser',
              password: 'some_password'
            )

            connection = double('connection')

            expect(Sequel).to receive(:connect).with(
              adapter: :mysql2,
              database: 'magento',
              host: 'magento-instance.domain.com',
              port: 1234,
              user: 'dbuser',
              password: 'some_password'
            ).and_return(connection)

            expect(connection).to receive(:disconnect)

            sql_client.connect { |db| nil }
          end
        end
      end
    end
  end
end
