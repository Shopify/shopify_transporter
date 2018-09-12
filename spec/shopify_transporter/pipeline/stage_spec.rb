# # frozen_string_literal: true

require 'shopify_transporter/pipeline/stage'

module ShopifyTransporter::Pipeline
  RSpec.describe Stage do
    it 'initializes without params' do
      expect { Stage.new }.not_to raise_error
    end
    it 'initializes with params' do
      expect { Stage.new('test_params') }.not_to raise_error
    end
    it 'raises a NotImplementedError when Stage#convert is called' do
      expect { Stage.new('test_params').convert({}, nil) }.to raise_error(NotImplementedError)
    end
  end
end
