# frozen_string_literal: true
require 'sequel'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe SQL do
        context ('#connect') do

          let(:sql_client) do
            SQL.new(
              database: 'magento',
              host: 'magento-instance.domain.com',
              port: 1234,
              user: 'dbuser',
              password: 'some_password'
            )
          end

          let(:connection) { double('connection') }

          it 'calls Sequel with the right parameters' do
            expect(Sequel).to receive(:connect).with(
              adapter: :mysql2,
              database: 'magento',
              host: 'magento-instance.domain.com',
              port: 1234,
              user: 'dbuser',
              password: 'some_password'
            ).and_return(connection)

            sql_client.connect { |db| nil }
          end

          it 'yields the db connection on SQL#connect' do
            connection = double('db connection')

            expect(Sequel).to receive(:connect).with(
              adapter: :mysql2,
              database: 'magento',
              host: 'magento-instance.domain.com',
              port: 1234,
              user: 'dbuser',
              password: 'some_password'
            ).and_yield(connection)

            sql_client.connect { |db| expect(db).to eq(connection) }
          end
        end
      end
    end
  end
end
