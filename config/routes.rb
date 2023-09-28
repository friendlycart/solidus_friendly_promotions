# frozen_string_literal: true

SolidusFriendlyPromotions::Engine.routes.draw do
  namespace :admin do
    resources :promotion_categories, except: [:show]
    resources :promotion_groups, only: [:index]

    resources :promotions do
      resources :promotion_rules
      resources :promotion_actions
      resources :promotion_codes, only: [:index, :new, :create]
      resources :promotion_code_batches, only: [:index, :new, :create] do
        get "/download", to: "promotion_code_batches#download", defaults: {format: "csv"}
      end
    end
  end
end
