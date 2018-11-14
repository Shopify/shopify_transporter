# frozen_string_literal: true
#
module ShopifyTransporter
  class ProductRecordBuilder < RecordBuilder
    def initialize(key_name, key_required)
      super(key_name, key_required)
    end

    def build(input)
      validate_related(input)

      # Why don't we need to worry about @last_record here the way we do in RecordBuilder?

      if has_parent?(input)
        result = yield parent_record(input)
        key = input['parent_id']
      else
        result = yield record_from(input)
        key = key_of(input)
      end

      @instances[key] = result
    end

    private

    def has_parent?(product)
      product['parent_id'].present?
    end

    def parent_record(product)
      parent_id = product['parent_id']
      record = @instances[parent_id] ||= {}
      record['variants'] ||= []
      @last_record = record
    end
  end
end
