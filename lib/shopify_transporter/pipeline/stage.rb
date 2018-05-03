# frozen_string_literal: true
module ShopifyTransporter
  module Pipeline
    class Stage
      attr_reader :params

      def initialize(params = nil)
        @params = params
      end

      def convert(_hash, _record)
        raise NotImplementedError
      end
    end
  end
end
