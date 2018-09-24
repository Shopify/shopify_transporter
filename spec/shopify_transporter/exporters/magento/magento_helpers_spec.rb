# frozen_string_literal: true
require 'sequel'
require 'shopify_transporter/exporters/magento/magento_helpers.rb'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe 'Magento Helpers Module' do
        describe '#in_batches' do
          it 'retrieves and yields data in batches based on the constant in SQL' do
            stub_const('ShopifyTransporter::Exporters::Magento::MagentoHelpers::BATCH_SIZE', 2)

            test_class = Class.new do
              include MagentoHelpers
            end.new

            database_table = double('database_table')
            batch_field_key = :parent_id

            expect(database_table).to receive(:first).and_return(batch_field_key => 0)
            expect(database_table).to receive(:last).and_return(batch_field_key => 4)

            expect(database_table).to receive(:where) do |args|
              if args[batch_field_key] == (4...6)
                [{ batch_field_key => 4, name: '4' }]
              else
                args[batch_field_key].map { |id| { batch_field_key => id, name: id.to_s } }
              end
            end.exactly(3).times

            expect { |b| test_class.in_batches(database_table, batch_field_key, &b) }.to yield_successive_args(
              [{ batch_field_key => 0, name: '0' }, { batch_field_key => 1, name: '1' }],
              [{ batch_field_key => 2, name: '2' }, { batch_field_key => 3, name: '3' }],
              [{ batch_field_key => 4, name: '4' }],
            )
          end
        end
      end
    end
  end
end
