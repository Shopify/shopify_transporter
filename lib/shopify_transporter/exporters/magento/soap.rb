# frozen_string_literal: true

require 'json'
require 'savon'

module ShopifyTransporter
  module Exporters
    module Magento
      class Soap
        def initialize(hostname, username, api_key)
          @hostname = hostname
          @username = username
          @api_key = api_key
        end

        def call(fn, params)
          soap_client.call(
            fn,
            message: { session_id: soap_session_id }.merge(params)
          )
        end

        private

        attr_accessor :hostname, :username, :api_key

        def soap_client
          @soap_client ||= Savon.client(
            wsdl: "https://#{hostname}/api/v2_soap?wsdl",
            open_timeout: 500,
            read_timeout: 500,
          )
        end

        def soap_session_id
          @soap_session_id ||= soap_client.call(
            :login,
            message: {
              username: username,
              api_key: api_key,
            }
          ).body[:login_response][:login_return]
        end
      end
    end
  end
end
