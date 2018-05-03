# frozen_string_literal: true
require 'factory_bot'

namespace :factory_bot do
  desc "Verify that all FactoryBot factories are valid"
  task :lint do
    FactoryBot.lint
  end
end
