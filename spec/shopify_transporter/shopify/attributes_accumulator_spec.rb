# frozen_string_literal: true
require 'shopify_transporter/shopify/attributes_accumulator'

module ShopifyTransporter
  module Shopify
    RSpec.describe AttributesAccumulator do
      let(:accumulator_that_accumulates_raw_input) do
        Class.new(described_class) do
          private

          def input_applies?(*)
            true
          end

          def attributes_from(input)
            input
          end
        end
      end

      it 'raises a not implemented error for input_applies? if it is not defined' do
        accumulator = described_class.new({})
        expect { accumulator.accumulate({}) }.to raise_error NotImplementedError
      end

      it 'raises a not implemented error for attributes_from if it is not defined' do
        mock_class = Class.new(described_class) do
          private

          def input_applies?(*)
            true
          end
        end

        accumulator = mock_class.new({})
        expect { accumulator.accumulate({}) }.to raise_error NotImplementedError
      end

      it 'raises an error if the initial value is not an array or hash' do
        accumulator = accumulator_that_accumulates_raw_input.new('invalid initial value')
        expect { accumulator.accumulate({}) }.to(
          raise_error 'Unexpected initial value. Initial value must be an array or a hash.'
        )
      end

      context '#accumulate' do
        it 'returns the original input if input_applies? is false' do
          mock_class = Class.new(described_class) do
            private

            def input_applies?(*)
              false
            end
          end

          accumulator = mock_class.new('initial_value')
          expect(accumulator.accumulate({})).to eq('initial_value')
        end

        it 'calls attributes_from on the input if input_applies? is true' do
          accumulator = described_class.new({})
          expect(accumulator).to receive(:input_applies?).and_return(true)
          expect(accumulator).to receive(:attributes_from).and_return({})
          accumulator.accumulate({})
        end

        it 'adds the attributes_from output to the input_value and returns accumulated value' \
          ' if the initial value is an array' do
          initial_value = [
            {
              'name' => 'buyer1',
            }
          ]

          input = {
            'name' => 'buyer2'
          }

          expected_output = initial_value.dup << input

          accumulator = accumulator_that_accumulates_raw_input.new(initial_value)
          expect(accumulator.accumulate(input)).to eq(expected_output)
        end

        it 'adds the attributes_from output to the input_value and returns accumulated value' \
          ' if the initial value is a hash' do
          initial_value = {
            'name' => 'buyer1',
          }

          input = {
            'email' => 'buyer1@example.com'
          }

          expected_output = initial_value.dup.merge!(input)

          accumulator = accumulator_that_accumulates_raw_input.new(initial_value)
          expect(accumulator.accumulate(input)).to eq(expected_output)
        end
      end
    end
  end
end
