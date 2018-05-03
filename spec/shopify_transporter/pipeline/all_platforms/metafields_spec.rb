# frozen_string_literal: true

require 'shopify_transporter/pipeline/all_platforms/metafields'

module ShopifyTransporter::Pipeline::AllPlatforms
  RSpec.describe Metafields do
    context '#convert' do
      it 'extracts the specified metafields from the input' do
        magento_customer = {}
        magento_customer['website'] = 'http://example.com'
        magento_customer['group'] = 'Online Buyer'

        pipeline_params = {
          'metafield_namespace' => 'migrations_namespace',
          'metafields' => [
            'website',
            'group',
          ],
        }

        expected_output = {
          'metafields' => [
            shopify_metafield('migrations_namespace', 'website', magento_customer['website']),
            shopify_metafield('migrations_namespace', 'group', magento_customer['group']),
          ],
        }

        expect(Metafields.new(pipeline_params).convert(magento_customer, {})).to eq(expected_output)
      end

      it 'does not extract unspecified columns as metafields' do
        magento_customer = {}
        magento_customer['unspecified_column'] = 'a value'

        pipeline_params = {
          'metafield_namespace' => 'migrations_namespace',
          'metafields' => ['website'],
        }

        expect(Metafields.new(pipeline_params).convert(magento_customer, {})).to eq({})
      end

      it 'does not create an empty metafields array if no metafields are specified' do
        magento_customer = {}
        pipeline_params = {}
        expect{ Metafields.new(pipeline_params).convert(magento_customer, {}) }.to raise_error(
          'Metafields not specified.'
        )
      end

      it 'sets the metafield namespace based on the params passed in' do
        magento_customer = {}
        magento_customer['website'] = 'a value'

        pipeline_params = {
          'metafield_namespace' => 'custom_namespace',
          'metafields' => ['website'],
        }

        converted_output = Metafields.new(pipeline_params).convert(magento_customer, {})
        expect(converted_output['metafields'][0]['namespace']).to eq(pipeline_params['metafield_namespace'])
      end

      it 'sets a default metafield namespace if not specified' do
        magento_customer = {}
        magento_customer['website'] = 'a value'

        pipeline_params = {
          'metafields' => ['website'],
        }

        converted_output = Metafields.new(pipeline_params).convert(magento_customer, {})
        expect(converted_output['metafields'][0]['namespace']).to eq(ShopifyTransporter::DEFAULT_METAFIELD_NAMESPACE)
      end

      it 'extracts non-nil values only if both valid and nil values are present' do
        magento_customer = {}
        magento_customer['group'] = nil
        magento_customer['campaign'] = 'an actual value'

        pipeline_params = {
          'metafields' => ['group', 'campaign'],
        }

        expected_output = {
          'metafields' => [
            shopify_metafield(ShopifyTransporter::DEFAULT_METAFIELD_NAMESPACE, 'campaign', magento_customer['campaign']),
          ],
        }

        expect(Metafields.new(pipeline_params).convert(magento_customer, {})).to eq(expected_output)
      end
    end

    private

    def shopify_metafield(namespace, key, value)
      {
        'key' => key,
        'value' => value,
        'value_type' => 'string',
        'namespace' => namespace,
      }
    end
  end
end
