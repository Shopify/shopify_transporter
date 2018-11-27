# frozen_string_literal: true

require 'json'
require 'savon'

module ShopifyTransporter
  module Exporters
    module Magento
      class Soap
        class FailedLoginError < Exporters::ExportError
          def initialize(error_message)
            sep = $INPUT_RECORD_SEPARATOR
            super("Unable to obtain SOAP session ID from server.#{sep + sep}Details:#{sep + error_message}")
          end
        end

        RETRY_SLEEP_TIME = 0.1
        MAX_RETRIES = 4

        def initialize(hostname: '', username: '', api_key: '', batch_config:)
          @hostname = hostname
          @username = username
          @api_key = api_key
          @batch_config = batch_config
        end

        def call(method, params)
          call_with_retries(method, params)
        end

        def call_in_batches(method:, params: {}, batch_index_column:)
          current_id = @batch_config['first_id']
          max_id = @batch_config['last_id']
          batch_size = @batch_config['batch_size']

          Enumerator.new do |enumerator|
            while current_id <= max_id
              end_of_range = current_id + batch_size - 1
              end_of_range = max_id if end_of_range >= max_id

              $stderr.puts "Processing batch: #{current_id}..#{end_of_range}"

              begin
                enumerator << call(
                  method,
                  params.merge(batching_filter(current_id, end_of_range, batch_index_column)),
                )
              rescue Savon::Error => e
                output = 'Skipping batch: '\
                  "#{current_id}..#{end_of_range} after #{MAX_RETRIES} retries because of an error."
                $stderr.puts output
                $stderr.puts 'The exact error was:'
                $stderr.puts "#{e.class}: "
                $stderr.puts e.message
              end

              current_id += batch_size
            end
          end
        end

        private

        def call_with_retries(method, params, retry_count = 0)
          soap_client.call(
            method,
            message: { session_id: soap_session_id }.merge(params)
          )
        rescue Savon::Error
          raise if retry_count >= MAX_RETRIES
          sleep(RETRY_SLEEP_TIME * (retry_count + 1))
          call_with_retries(method, params, retry_count + 1)
        end

        def soap_client
          @soap_client ||= Savon.client(
            wsdl: "#{hostname_with_scheme}/api/v2_soap?wsdl",
            open_timeout: 500,
            read_timeout: 500,
          )
        end

        def hostname_with_scheme
          URI.parse(@hostname).scheme.present? ? @hostname : 'https://' + @hostname
        end

        def soap_session_id
          return @soap_session_id if @soap_session_id.present?

          result = soap_client.call(
            :login,
            message: {
              username: @username,
              api_key: @api_key,
            }
          ).body

          session_id = result&.dig(:login_response, :login_return) || result&.dig(:login_response_param, :result)
          raise FailedLoginError, result.to_s unless session_id.present?

          @soap_session_id ||= session_id
        end

        def batching_filter(starting_id, ending_id, batch_index_column)
          {
            filters: {
              'complex_filter' => [
                item: [
                  {
                    key: batch_index_column,
                    value: {
                      key: 'in',
                      value: range_id_string(starting_id, ending_id),
                    },
                  },
                ],
              ],
            },
          }
        end

        def range_id_string(starting_id, ending_id)
          (starting_id..ending_id).to_a.join(',')
        end
      end
    end
  end
end
