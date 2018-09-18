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
            expect(connection).to receive(:disconnect)

            sql_client.connect { |db| nil }
          end

          it 'disconnects the database even if the given block raises an error' do
            expect(Sequel).to receive(:connect).with(
              adapter: :mysql2,
              database: 'magento',
              host: 'magento-instance.domain.com',
              port: 1234,
              user: 'dbuser',
              password: 'some_password'
            ).and_return(connection)
            expect(connection).to receive(:disconnect)

            expect do
              sql_client.connect { |db| raise('database lost connection!') }
            end.to raise_error('database lost connection!')
          end
        end
      end
    end
  end
end
