# frozen_string_literal: true
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Shopify
    RSpec.describe Record do
      let(:subject) { Class.new(Record) }

      context '.header' do
        it 'raises NotImplementedError' do
          expect{subject.header}.to raise_error(NotImplementedError)
        end
      end

      context '#to_csv' do
        it 'raises NotImplementedError' do
          expect{subject.new.to_csv}.to raise_error(NotImplementedError)
        end
      end
    end
  end
end
