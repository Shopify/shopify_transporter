# frozen_string_literal: true
require 'shopify_transporter/shopify/attributes_helpers'
RSpec.describe ShopifyTransporter::Shopify::AttributesHelpers, type: :helper do
  let(:dummy_class) { Class.new { extend ShopifyTransporter::Shopify::AttributesHelpers } }

  context '#attributes_present?' do
    it 'returns truthy if the attribute key exists' do
      new_row = {address: '123 sesame street', name: 'fahia'}
      expect(dummy_class.attributes_present?(new_row, :address)).to be(true)
    end
    it 'returns falsey when the value is nil' do
      row = { phone: 534343, name: 'fahia' }
      expect(dummy_class.attributes_present?(row, :address)).to be(false)
    end
    it 'returns falsey when the value is present but empty' do
      row = { phone: 534343, name: 'fahia', address: {} }
      expect(dummy_class.attributes_present?(row, :address)).to be(false)
    end
  end

  it 'adds a prefix' do
    prefix_to_be_added = 'billing_'
    expect(dummy_class.add_prefix(prefix_to_be_added, 'address')).to eq(['billing_address'.to_sym])
  end

  it 'drops a prefix' do
    prefix_to_be_dropped = 'billing_'
    row = { billing_address: ['something'] }
    expect(dummy_class.drop_prefix(row, prefix_to_be_dropped).keys).to eq([:address])
  end

  it 'deletes empty attributes' do
    row = {name: 'fahia', email: '', phone: '', address: []}
    expect(dummy_class.delete_empty_attributes(row)).to eq({name: 'fahia'})
  end

  context '#normalize_keys' do
    it 'transforms keys from hyphen separated to underscore separated' do
      row = { 'first-name' => 'fahia', 'email-address' => 'f@s.ca' }
      expect(dummy_class.normalize_keys(row).keys).to eq([:first_name, :email_address])
    end
    it 'replaces special characters in a string' do
      row = { 'first.name' => 'fahia', 'email.address' => 'f@s.ca' }
      expect(dummy_class.normalize_keys(row).keys).to eq([:first_name, :email_address])
    end
    it 'downcases characters' do
      row = { 'First.Name' => 'fahia', 'Email.Address' => 'f@s.ca' }
      expect(dummy_class.normalize_keys(row).keys).to eq([:first_name, :email_address])
    end
  end

  it 'renames fields using a field_map' do
    field_map = {
      'First Name' => 'first_name',
      'Last Name' => 'last_name',
      'Email Address' => 'email'
    }
    row = { 'First Name' => 'Fahia', 'Last Name' => 'Mohamed', 'Email Address' => 'fahia.mohamed@test.com' }
    expect(dummy_class.rename_fields(row, field_map).keys).to eq(['first_name', 'last_name', 'email'])
  end

  it 'maps specified keys to values given a key value mapping' do
    field_map = {
      'First Name' => 'first_name',
      'Last Name' => 'last_name',
      'Email Address' => 'email'
    }
    row = { 'First Name' => 'Fahia', 'Last Name' => 'Mohamed', 'Email Address' => 'fahia.mohamed@test.com' }
    expect(dummy_class.map_from_key_to_val(field_map, row).keys).to eq(['first_name', 'last_name', 'email'])
  end

  context '#shopify_metafield_hash' do
    it 'creates a Shopify metafield hash from passed in parameters' do
      expect(dummy_class.shopify_metafield_hash(
        key: 'test_key',
        value: 'test_value',
        value_type: 'integer',
        namespace: 'test_namespace'
      )).to eq({
        'key' => 'test_key',
        'value' => 'test_value',
        'value_type' => 'integer',
        'namespace' => 'test_namespace',
      })
    end

    it 'sets a default value type if not specified' do
      expect(dummy_class.shopify_metafield_hash(
        key: 'test_key',
        value: 'test_value',
        namespace: 'test_namespace'
      )).to eq({
        'key' => 'test_key',
        'value' => 'test_value',
        'value_type' => 'string',
        'namespace' => 'test_namespace',
      })
    end
  end
end

