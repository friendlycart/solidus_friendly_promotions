class CreatePromotionGroups < ActiveRecord::Migration[7.0]
  def change
    create_table :friendly_promotion_groups do |t|
      t.string :name, null: false
      t.integer :position

      t.timestamps
    end

    add_reference :friendly_promotions,
      :friendly_promotion_group,
      foreign_key: true

    SolidusFriendlyPromotions::PromotionGroup::GROUP_PRIORITY_NAMES.each_with_index do |group, index|
      SolidusFriendlyPromotions::PromotionGroup.find_or_create_by!(name: group, position: index)
    end
  end
end
