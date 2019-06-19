# frozen_string_literal: true

module ShopifyTransporter
  class KeyMissing < StandardError
    def initialize(key_name)
      super("cannot process entry. Required field not found: '#{key_name}'")
    end
  end

  class RequiredKeyMissing < KeyMissing; end

  class MissingParentObject < KeyMissing; end

  class RecordBuilder
    attr_accessor :instances

    def initialize(key_name, key_required)
      @instances = {}
      @key_name = key_name
      @key_required = key_required
    end

    def build(input)
      validate_related(input)

      if key_of(input).nil?
        result = yield @last_record
      else
        result = yield record_from(input)
      end

      @instances[key_of(input)] = result
    end

    private

    def validate_related(input)
      raise MissingParentObject, @key_name if key_of(input).nil? && @last_record.nil?
    end

    def record_from(input)
      record = @instances[key_of(input)] ||= {}
      @last_record = record
    end

    def key_of(input)
      record_key = input[@key_name]
      raise RequiredKeyMissing, @key_name if @key_required && record_key.nil?
      record_key
    end
  end
end
