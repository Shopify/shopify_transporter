# frozen_string_literal: true
module ShopifyTransporter
  class BaseGroup < Thor::Group
    include Thor::Actions
    argument :name

    SUPPORTED_PLATFORMS_MAPPING = {
      'Magento' => 'magento',
      'BigCommerce' => 'bc',
    }

    def name_components
      @name_components ||= name.scan(/[[:alnum:]]+/)
    end

    def config_filename
      'config.yml'
    end

    class << self
      def source_root
        File.expand_path('../../', File.dirname(__FILE__))
      end
    end
  end
end
