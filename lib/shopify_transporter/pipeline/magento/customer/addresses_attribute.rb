# frozen_string_literal: true
require 'shopify_transporter/pipeline/stage'
require 'shopify_transporter/shopify'

module ShopifyTransporter
  module Pipeline
    module Magento
      module Customer
        class AddressesAttribute < Pipeline::Stage
          def convert(input, record)
            addresses = magento_addresses_from(input)
            return unless addresses

            record.merge!(convert_addresses(addresses))
          end

          private

          COLUMN_MAPPING = {
            'firstname' => 'first_name',
            'lastname' => 'last_name',
            'street' => 'address1',
            'city' => 'city',
            'region' => 'province',
            'country_id' => 'country_code',
            'postcode' => 'zip',
            'company' => 'company',
            'telephone' => 'phone',
          }

          def convert_addresses(addresses)
            {
              'addresses' => [
                *addresses_from(addresses.select { |address| address['is_default_shipping'] }),
                *addresses_from(addresses.select { |address| !address['is_default_shipping'] }),
              ].compact,
            }
          end

          def addresses_from(addresses)
            return nil unless addresses.present?

            addresses.map do |address|
              COLUMN_MAPPING.each_with_object({}) do |(key, value), obj|
                obj[value] = address[key] if address[key]
              end
            end
          end

          def magento_addresses_from(input)
            addresses = input.dig('address_list', 'customer_address_list_response', 'result', 'item')
            return nil unless addresses

            addresses.is_a?(Array) ? addresses : [addresses]
          end
        end
      end
    end
  end
end
