# frozen_string_literal: true
require 'shopify_transporter/record_builder'

RSpec.describe ShopifyTransporter::RecordBuilder do
  let(:record_class) do
    Class.new do
      class << self
        def header
        end

        def csv_values
        end
      end
    end
  end

  let(:builder_class) do
    Class.new(ShopifyTransporter::RecordBuilder) do
      class << self
        def key
        end
      end
    end
  end

  subject { builder_class.new("key_name", true) }

  describe '#build' do
    it "builds a new record if the record's key wasn't previosly seen (using #key_of)" do
      subject.build({'key_name' => 'key_value'}) { |record| expect(record).to eq({}) }
    end

    it 'passes the matching record to the provided block' do
      input = {'key_name' => 'key_value'}
      subject.build(input) { |record| record['modified'] = true }
      subject.build(input) { |record| expect(record).to eq('modified' => true) }
    end

    it 'returns the value returned by the provided block' do
      expect(subject.build({'key_name' => 'key_value'}) { |_| 7 }).to eq(7)
    end

    context 'when a key is required' do
      it "raises an error when the key is missing" do
        expected_message = "cannot process entry. Required field not found: 'key_name'"
        expect{subject.build({})}.to raise_error(ShopifyTransporter::RequiredKeyMissing, expected_message)
      end
    end

    context "when a key is not required" do
      subject { builder_class.new("key_name", false) }

      it "raises an error when the the input does not have a key and a previously yielded record does not exist" do
        expected_message = "cannot process entry. Required field not found: 'key_name'"
        expect{subject.build({})}.to raise_error(ShopifyTransporter::MissingParentObject, expected_message)
      end

      it "yields the last record when the input doesn't contain the key" do
        input1 = {'key_name' => 'key_value'}
        input2 =  { }

        subject.build(input1) { |record| record['modified'] = true }
        subject.build(input2) { |record| expect(record).to eq('modified' => true) }
      end
    end
  end
end
