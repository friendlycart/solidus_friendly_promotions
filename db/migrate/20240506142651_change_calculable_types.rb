class ChangeCalculableTypes < ActiveRecord::Migration[6.1]
  def up
    sql = <<~SQL
      UPDATE spree_calculators
      SET calculable_type = REPLACE(calculable_type, 'SolidusFriendlyPromotions::PromotionAction', 'SolidusFriendlyPromotions::Benefit')
    SQL
    execute(sql)
  end

  def down
    sql = <<~SQL
      UPDATE spree_calculators
      SET calculable_type = REPLACE(calculable_type, 'SolidusFriendlyPromotions::Benefit', 'SolidusFriendlyPromotions::PromotionAction')
    SQL
    execute(sql)
  end
end
