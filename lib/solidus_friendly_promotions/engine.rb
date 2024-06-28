# frozen_string_literal: true

require "solidus_core"
require "solidus_support"

module SolidusFriendlyPromotions
  class Engine < Rails::Engine
    include SolidusSupport::EngineExtensions

    isolate_namespace ::SolidusFriendlyPromotions

    engine_name "solidus_friendly_promotions"

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    initializer "solidus_friendly_promotions.assets" do |app|
      app.config.assets.precompile << "solidus_friendly_promotions/manifest.js"
    end

    initializer "solidus_promotions.spree_config", after: "spree.load_config_initializers" do
      Rails.application.config.to_prepare do
        Spree::Order.line_item_comparison_hooks << :free_from_order_benefit?
      end
    end

    initializer "solidus_friendly_promotions.importmap" do |app|
      SolidusFriendlyPromotions.importmap.draw(Engine.root.join("config", "importmap.rb"))

      package_path = Engine.root.join("app/javascript")
      app.config.assets.paths << package_path

      if app.config.importmap.sweep_cache
        SolidusFriendlyPromotions.importmap.cache_sweeper(watches: package_path)
        ActiveSupport.on_load(:action_controller_base) do
          before_action { SolidusFriendlyPromotions.importmap.cache_sweeper.execute_if_updated }
        end
      end
    end
  end
end
