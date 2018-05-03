# frozen_string_literal: true
require_relative 'attributes_helpers'

module ShopifyTransporter
  module Shopify
    class AttributesAccumulator
      include AttributesHelpers

      attr_reader :output

      def initialize(initial_value)
        @output = initial_value
      end

      def accumulate(input)
        return @output unless input_applies?(input)
        attributes = attributes_from(input)
        accumulate_attributes(attributes)
      end

      private

      def input_applies?(_input)
        raise NotImplementedError
      end

      def attributes_from(_input)
        raise NotImplementedError
      end

      def accumulate_attributes(attributes)
        case @output
        when Array
          @output << attributes
        when Hash
          @output.merge!(attributes)
        else
          raise 'Unexpected initial value. Initial value must be an array or a hash.'
        end
      end
    end
  end
end
