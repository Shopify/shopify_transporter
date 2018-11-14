# frozen_string_literal: true
#
module ShopifyTransporter
  class ProductRecordBuilder < RecordBuilder
    def initialize(key_name, key_required)
      super(key_name, key_required)
    end

    def build(input)
      validate_related(input)

      if has_parent?(input)
      #  binding.pry
        result = yield parent_record(input)
        return
      end

      result = yield record_from(input)

      @instances[key_of(input)] = result
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
