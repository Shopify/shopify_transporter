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
        yield parent_record(input)
        return
      end

      yield record_from(input)
    end

    private

    def has_parent?(product)
      product['parent_id'].present?
    end

    def parent_record(product)
      parent_id = product['parent_id']
      record = @instances[parent_id] ||= {}
      @last_record = record
    end
  end
end
