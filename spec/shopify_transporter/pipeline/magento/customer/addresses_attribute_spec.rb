# frozen_string_literal: true

require 'shopify_transporter/pipeline/magento/customer/addresses_attribute'

module ShopifyTransporter::Pipeline::Magento::Customer
  RSpec.describe AddressesAttribute, type: :helper do
    def address_from(magento_address)
      {
        'first_name' => magento_address['firstname'],
        'last_name' => magento_address['lastname'],
        'address1' => magento_address['street'],
        'city' => magento_address['city'],
        'province' => magento_address['region'],
        'country_code' => magento_address['country_id'],
        'zip' => magento_address['postcode'],
        'company' => magento_address['company'],
        'phone' => magento_address['telephone'],
      }
    end

    def strip_defaults_from(magento_addresses)
      magento_addresses.each do |address|
        address['is_default_shipping'] = false
        address['is_default_billing'] = false
      end
    end

    context '#convert' do
      it 'does not add an addresses attribute when the magento addresses do not exist' do
        magento_customer = FactoryBot.build(:magento_customer)
        magento_customer.except!('address_list')
        record = {}
        described_class.new.convert(magento_customer, record)
        expect(record).not_to include('addresses') 
      end

      it 'builds a single address when the magento address is a hash containing a single address' do
        magento_customer = FactoryBot.build(:magento_customer, address_count: 1)
        address = magento_customer['address_list']['customer_address_list_response']['result']['item']
        address['is_default_shipping'] = true
        record = {}
        described_class.new.convert(magento_customer, record) 
        expect(record['addresses']).to eq(
          [
            address_from(address),
          ]
        )
      end
      
      context 'when the magento address is an array containing multiple addresses' do
        it 'builds the first address from the default shipping address and subsequent addresses from the non-default shipping address' do
          magento_customer = FactoryBot.build(:magento_customer, address_count: 3)
          addresses = magento_customer['address_list']['customer_address_list_response']['result']['item']
          strip_defaults_from(addresses)

          addresses[1]['is_default_shipping'] = true
          record = {}
          described_class.new.convert(magento_customer, record)
          expect(record['addresses']).to eq(
            [
              address_from(addresses[1]),
              address_from(addresses[0]),
              address_from(addresses[2]),
            ]
          )
        end
      end
    end
  end
end
