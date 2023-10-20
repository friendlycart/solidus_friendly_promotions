# frozen_string_literal: true

module SolidusFriendlyPromotions
  class PromotionEligibility
    attr_reader :promotable, :promotion, :eligibility_errors

    def initialize(promotable:, promotion:, eligibility_errors: nil)
      @promotable = promotable
      @promotion = promotion
      @eligibility_errors = eligibility_errors
    end

    def call
      applicable_rules = promotion.rules.select do |rule|
        rule.applicable?(promotable)
      end

      applicable_rules.map do |applicable_rule|
        result = applicable_rule.eligible?(promotable)

        unless result
          eligibility_errors.add(applicable_rule.eligibility_errors)
          break [false] unless eligibility_errors
        end

        result
      end.all?
    end
  end
end
