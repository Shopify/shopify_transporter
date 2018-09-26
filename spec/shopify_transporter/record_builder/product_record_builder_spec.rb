# frozen_string_literal: true
require 'shopify_transporter/record_builder/record_builder'

RSpec.describe ShopifyTransporter::ProductRecordBuilder do

  before(:all) do
    @builder = ShopifyTransporter::ProductRecordBuilder.new("product_id", true)
  end

  describe '#build' do
    it "Should yield an empty record if the product does not have a parent id and the product_id wasn't previously seen" do
      @builder.build({'product_id' => '1'}) do |record|
        expect(record).to eq({})
        record['is_parent'] = true
        record['key1'] = 'val1'
      end
    end

    it "Should yield the parent record if the product has a parent id and the parent has been stored" do
      @builder.build({'product_id' => '2', 'parent_id' => '1'}) do |record|
        expect(record).to include('is_parent' => true, 'key1' => 'val1')
      end
    end

    it "Should yield an record with empry variants if the product has a parent id and its parent wasn't previously seen" do
      @builder.build({'product_id' => '3', 'parent_id' => '4'}) do |record|
        expect(record).to eq({"variants"=>[]})
        record['key2'] = 'val2'
      end
    end

    it "Should yield the parent record if the product has children who have been already processed" do
      @builder.build({'product_id' => '4'}) do |record|
        expect(record).to include('key2' => 'val2')
      end
    end

    end
end
