class RemoveConditionsPromotionId < ActiveRecord::Migration[6.1]
  def up
    remove_column :friendly_conditions, :promotion_id
  end
end
