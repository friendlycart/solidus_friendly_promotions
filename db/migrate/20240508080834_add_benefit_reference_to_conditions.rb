class AddBenefitReferenceToConditions < ActiveRecord::Migration[6.1]
  def up
    remove_foreign_key :friendly_conditions, :friendly_promotions
    change_column :friendly_conditions, :promotion_id, :integer, null: true

    add_reference :friendly_conditions, :benefit, index: {name: :condition}, null: true, foreign_key: {to_table: :friendly_benefits}

    SolidusFriendlyPromotions::Condition.reset_column_information

    SolidusFriendlyPromotions::Benefit.find_each do |benefit|
      SolidusFriendlyPromotions::Condition.where(promotion_id: benefit.promotion_id).each do |condition|
        condition.dup.tap do |new_condition|
          new_condition.preload_relations.each do |relation|
            new_condition.send(:"#{relation}=", condition.send(relation).dup)
          end
          new_condition.benefit = benefit
          new_condition.save!
        end
        condition.destroy!
      end
    end
  end

  def down
    SolidusFriendlyPromotions::Condition.where.not(benefit_id: nil).delete_all
    change_column :friendly_conditions, :promotion_id, :integer, null: true
    add_foreign_key :friendly_conditions, :friendly_promotions, column: :promotion_id
  end
end
