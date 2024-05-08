# frozen_string_literal: true

FactoryBot.define do
  factory :friendly_promotion, class: "SolidusFriendlyPromotions::Promotion" do
    name { "Promo" }
    customer_label { "Because we like you" }

    transient do
      code { nil }
    end
    before(:create) do |promotion, evaluator|
      if evaluator.code
        promotion.codes << build(:friendly_promotion_code, promotion: promotion, value: evaluator.code)
      end
    end

    trait :with_adjustable_benefit do
      transient do
        preferred_amount { 10 }
        calculator_class { SolidusFriendlyPromotions::Calculators::FlatRate }
        promotion_benefit_class { SolidusFriendlyPromotions::Benefits::AdjustLineItem }
        conditions { [] }
      end

      after(:create) do |promotion, evaluator|
        calculator = evaluator.calculator_class.new
        calculator.preferred_amount = evaluator.preferred_amount
        evaluator.promotion_benefit_class.create!(calculator: calculator, promotion: promotion, conditions: evaluator.conditions)
      end
    end

    factory :friendly_promotion_with_benefit_adjustment, traits: [:with_adjustable_benefit]

    trait :with_line_item_adjustment do
      transient do
        adjustment_rate { 10 }
      end

      with_adjustable_benefit
      preferred_amount { adjustment_rate }
    end

    factory :friendly_promotion_with_item_adjustment, traits: [:with_line_item_adjustment]

    trait :with_free_shipping do
      after(:create) do |promotion|
        calculator = SolidusFriendlyPromotions::Calculators::Percent.new(preferred_percent: 100)

        SolidusFriendlyPromotions::Benefits::AdjustShipment.create!(promotion: promotion, calculator: calculator)
      end
    end

    trait :with_order_adjustment do
      transient do
        weighted_order_adjustment_amount { 10 }
      end

      with_adjustable_benefit
      preferred_amount { weighted_order_adjustment_amount }
      calculator_class { SolidusFriendlyPromotions::Calculators::DistributedAmount }
    end

    factory :friendly_promotion_with_order_adjustment, traits: [:with_order_adjustment]
  end
end
