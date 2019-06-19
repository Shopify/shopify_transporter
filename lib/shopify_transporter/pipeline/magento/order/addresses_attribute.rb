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
            record.merge(
              {
                billing_address: address_attributes(input, BILLING_PREFIX),
                shipping_address: address_attributes(input, SHIPPING_PREFIX),
              }.deep_stringify_keys
            )
          end

          private

          def get_nested_address(input, prefix)
            items = input['items']
            result = items && items['result']
            address = result && result["#{prefix}address"]
            address ||= []
            clean_address(input, address, prefix)
          end

          def clean_address(input, address, prefix)
            address.each_with_object({}) do |(key, val), purged_address|
              if val.is_a?(String)
                purged_address[key] = val
              else
                address_type = prefix.chomp('_')
                warning = "Warning: Order #{input['increment_id']} - "\
                  "#{key} of the #{address_type} address is in an unexpected format. "\
                  "Transporter CLI expects it to be a string. Skipping #{key}."
                $stderr.puts warning
              end
            end
          end

          def address_attributes(input, prefix)
            address_attrs = get_nested_address(input, prefix)
            return address_attrs unless address_attrs.present?

            {
              first_name: address_attrs['firstname'],
              last_name: address_attrs['lastname'],
              name: name(address_attrs),
              phone: address_attrs['telephone'],
              address1: address_attrs['street'],
              city: address_attrs['city'],
              province_code: address_attrs['region'],
              zip: address_attrs['postcode'],
              country_code: address_attrs['country_id'],
              company: address_attrs['company'],
            }
          end

          def name(address_attrs)
            if address_attrs['firstname'].present? && address_attrs['lastname'].present?
              address_attrs['firstname'] + ' ' + address_attrs['lastname']
            end
          end
        end
      end
    end
  end
end
