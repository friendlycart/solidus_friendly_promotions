# frozen_string_literal: true

require "factory_bot"
begin
  require "factory_bot_rails"
rescue LoadError
end

module SolidusFriendlyPromotions
  module TestingSupport
    module FactoryBot
      SEQUENCES = ["#{::SolidusFriendlyPromotions::Engine.root}/lib/solidus_friendly_promotions/testing_support/sequences.rb"]
      FACTORIES = Dir["#{::SolidusFriendlyPromotions::Engine.root}/lib/solidus_friendly_promotions/testing_support/factories/**/*_factory.rb"].sort
      PATHS = SEQUENCES + FACTORIES

      def self.definition_file_paths
        @paths ||= PATHS.map { |path| path.sub(/.rb\z/, "") }
      end

      def self.add_definitions!
        ::FactoryBot.definition_file_paths.unshift(*definition_file_paths).uniq!
      end

      def self.add_paths_and_load!
        add_definitions!
        ::FactoryBot.reload
      end
    end
  end
end
