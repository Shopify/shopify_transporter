# frozen_string_literal: true
require 'savon'
require 'json'

class TransporterExporter

  TIMEOUT_DURATION = 10

  class MagentoTimeoutError < StandardError
  end

  class ExportError < StandardError
    def initialize(message)
      super(message)
    end
  end

  def run
    raise NotImplementedError
  end

  private

  def key
    raise NotImplementedError
  end

  REQUIRED_ENV_VARS = %w(
    MAGENTO_SOAP_API_HOSTNAME
    MAGENTO_SOAP_API_USERNAME
    MAGENTO_SOAP_API_KEY
    MAGENTO_STORE_ID
  ).freeze

  OPTIONAL_ENV_VARS = %w(LAST_KEY_ID).freeze

  def soap_client
    @soap_client ||= Savon.client(
      wsdl: "http://#{required_env_vars['MAGENTO_SOAP_API_HOSTNAME']}/api/v2_soap?wsdl",
      open_timeout: 500,
      read_timeout: 500,
      convert_request_keys_to: :none
    )
  end

  def soap_session_id
    @soap_session_id ||= soap_client.call(
      :login,
      message: {
        username: required_env_vars['MAGENTO_SOAP_API_USERNAME'],
        apiKey: required_env_vars['MAGENTO_SOAP_API_KEY'],
      }
    ).body[:login_response][:login_return]
  end

  def filters
    {
      filter: {
        item: {
          key: 'store_id',
          value: required_env_vars['MAGENTO_STORE_ID'],
        }
      }
    }
  end

  def filter_by_date_range(start_location, end_location)
    {
      complex_filter: [
        item: [
          {
            key: 'created_at',
            value: {
                key: 'from',
                value: start_location.strftime("%Y-%m-%d %H:%M:%S"),
            }
          },
          {
            key: 'CREATED_AT',
            value: {
                key: 'to',
                value: end_location.strftime("%Y-%m-%d %H:%M:%S"),
            }
          },
        ]
      ]
    }
  end

  def skip?(item)
    return false if optional_env_vars['LAST_KEY_ID'].nil? || item[key].nil?

    item[key].to_i < optional_env_vars['LAST_KEY_ID'].to_i
  end

  def write_to_file(filename, str)
    open(filename, 'a') do |f|
      flock(f, File::LOCK_EX) do |f_locked|
        f_locked.puts str
      end
    end
  end

  def flock(file, mode)
    success = file.flock(mode)
    if success
      begin
        yield file
      ensure
        file.flock(File::LOCK_UN)
      end
    end
  end

  def required_env_vars
    @required_env_vars ||= env_vars(REQUIRED_ENV_VARS, true)
  end

  def optional_env_vars
    @optional_env_vars ||= env_vars(OPTIONAL_ENV_VARS, false)
  end

  def env_vars(vars, required = false)
    vars.each_with_object({}) do |var, hash|
      raise ExportError, "Missing environment variable: #{var}" if required && ENV[var].nil?
      next if !required && ENV[var].nil?

      hash[var] = ENV[var]
    end
  end
end
