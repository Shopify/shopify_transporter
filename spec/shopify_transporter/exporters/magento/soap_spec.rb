# frozen_string_literal: true
require 'sequel'

module ShopifyTransporter
  module Exporters
    module Magento
      RSpec.describe Soap do
        let(:init_params) do
          {
            hostname: 'example.com',
            username: 'testuser',
            api_key: 'testapikey',
            batch_config: {},
          }
        end

        def stub_client_call(mock_client)
          expect(Savon).to receive(:client).with(
            wsdl: "https://example.com/api/v2_soap?wsdl",
            open_timeout: 500,
            read_timeout: 500,
          ).and_return(mock_client)
        end

        def stub_login_call(mock_client)
          login_response = double('login_response')

          expect(mock_client).to receive(:call).with(
            :login,
            message: {
              username: 'testuser',
              api_key: 'testapikey',
            }
          ).and_return(
            login_response
          )

          expect(login_response).to receive(:body).and_return(
            login_response: {
              login_return: '123',
            },
          )
        end

        describe '#call' do
          it 'initializes savon with the right parameters' do
            mock_client = spy('mock_client')
            stub_client_call(mock_client)

            Soap.new(init_params).call(:test_call, {})
          end

          it 'creates a session' do
            mock_client = spy('mock_client')
            stub_client_call(mock_client)
            stub_login_call(mock_client)

            Soap.new(init_params).call(:test_call, {})
          end

          it 'calls Savon with the fn, session_id and params' do
            mock_client = spy('mock_client')
            stub_client_call(mock_client)
            stub_login_call(mock_client)

            expect(mock_client).to receive(:call).with(
              :test_call,
              message: {
                session_id: '123',
              },
            )

            Soap.new(init_params).call(:test_call, {})
          end

          it 'retries soap calls up to 4 times with a delay when there is a savon error' do
            mock_client = spy('mock_client')
            stub_client_call(mock_client)
            stub_login_call(mock_client)

            soap_instance = Soap.new(init_params)

            retries = 0
            expect(mock_client).to receive(:call).with(
              :test_call,
              message: {
                session_id: '123',
              },
            ) do |args|
              if retries < 4
                expect(soap_instance).to receive(:sleep).with(described_class::RETRY_SLEEP_TIME * (retries + 1))
                retries += 1
                raise Savon::Error, 'Soap call failed.'
              end
            end.exactly(described_class::MAX_RETRIES + 1).times

            soap_instance.call(:test_call, {})
          end
        end

        describe '#call_in_batches' do
          def expected_batching_filter(batch_key, batch_range_string)
            {
              'complex_filter' => [
                item: [
                  {
                    key: batch_key,
                    value: {
                      key: 'in',
                      value: batch_range_string,
                    },
                  },
                ],
              ],
            }
          end

          it 'returns an enumerator with the results of #call for each batch specified' do
            soap_client = Soap.new(init_params.merge(
              batch_config: {
                'first_id' => 0,
                'last_id' => 7,
                'batch_size' => 3,
              }
            ))

            ['0,1,2', '3,4,5', '6,7'].each_with_index do |batch_range_string, index|
              expect(soap_client).to receive(:call).with(:test_call,
                filters: expected_batching_filter(
                  'customer_id',
                  batch_range_string
                )).and_return(["batch-#{index}"])
            end

            expect { |b| soap_client.call_in_batches(method: :test_call, batch_index_column: 'customer_id').each(&b) }
              .to yield_successive_args(['batch-0'], ['batch-1'], ['batch-2'])
          end

          it 'works when first id and last id are the same' do
            soap_client = Soap.new(init_params.merge(
              batch_config: {
                'first_id' => 0,
                'last_id' => 0,
                'batch_size' => 3,
              }
            ))

            expect(soap_client).to receive(:call).with(:test_call,
              filters: expected_batching_filter(
                'increment_id',
                '0'
            )).and_return(["batch-0"])

            expect { |b| soap_client.call_in_batches(method: :test_call, batch_index_column: 'increment_id').each(&b) }
              .to yield_successive_args(['batch-0'])
          end

          it 'correctly merges params passed in with the batching filter' do
            soap_client = Soap.new(init_params.merge(
              batch_config: {
                'first_id' => 0,
                'last_id' => 0,
                'batch_size' => 3,
              }
            ))

            test_params = {
              test_key: {
                item: {
                  key: 'store_id',
                  value: 5,
                },
              },
            }

            expected_params_hash = test_params.merge(
              filters: expected_batching_filter('increment_id', '0')
            )

            expect(soap_client).to receive(:call)
              .with(:test_call, expected_params_hash)
              .and_return(['batch-0'])

            expect do |b|
              soap_client
                .call_in_batches(method: :test_call, batch_index_column: 'increment_id', params: test_params).each(&b)
            end.to yield_successive_args(['batch-0'])
          end
        end
      end
    end
  end
end
