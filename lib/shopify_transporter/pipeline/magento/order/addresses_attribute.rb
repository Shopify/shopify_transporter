# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'
module ShopifyTransporter
  module Pipeline
    module Magento
      module Order
        class AddressesAttribute < Pipeline::Stage
          BILLING_PREFIX = 'billing_'
          SHIPPING_PREFIX = 'shipping_'

          def convert(input, record)
            record['billing_address'] = address_attributes(input, BILLING_PREFIX)
            record['shipping_address'] = address_attributes(input, SHIPPING_PREFIX)
            record
          end

          private

          def get_nested_address(input, prefix)
            items = input['items']
            result = items && items['result']
            address = result && result["#{prefix}address"]
            address || []
          end

          def address_attributes(input, prefix)
            address_attrs = get_nested_address(input, prefix)
            return address_attrs unless address_attrs.present?

            {
              first_name: address_attrs['firstname'],
              last_name: address_attrs['lastname'],
              phone: address_attrs['telephone'],
              address1: address_attrs['street'],
              city: address_attrs['city'],
              province_code: address_attrs['region'],
              zip: address_attrs['postcode'],
              country_code: address_attrs['country_id'],
            }
          end
        end
      end
    end
  end
end
