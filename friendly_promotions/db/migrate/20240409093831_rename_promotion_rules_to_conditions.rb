class RenamePromotionRulesToConditions < ActiveRecord::Migration[7.0]
  def up
    rename_table :friendly_promotion_rules, :friendly_conditions
    rename_table :friendly_promotion_rules_stores, :friendly_condition_stores
    rename_table :friendly_promotion_rules_taxons, :friendly_condition_taxons
    rename_table :friendly_promotion_rules_users, :friendly_condition_users
    rename_table :friendly_products_promotion_rules, :friendly_condition_products
    rename_column :friendly_condition_stores, :promotion_rule_id, :condition_id
    rename_column :friendly_condition_taxons, :promotion_rule_id, :condition_id
    rename_column :friendly_condition_users, :promotion_rule_id, :condition_id
    rename_column :friendly_condition_products, :promotion_rule_id, :condition_id
    solidus_sql = <<~SQL
      UPDATE friendly_conditions
      SET type = REPLACE(type, 'SolidusFriendlyPromotions::Rules', 'SolidusFriendlyPromotions::Conditions')
    SQL
    execute(solidus_sql)

    cs_sql = <<~SQL
      UPDATE friendly_conditions
      SET type = REPLACE(type, 'Cs::Promotion::Rules', 'Cs::Promotion::Conditions')
    SQL
    execute(cs_sql)
  end

  def down
    rename_table :friendly_conditions, :friendly_promotion_rules
    rename_table :friendly_condition_stores, :friendly_promotion_rules_stores
    rename_table :friendly_condition_taxons, :friendly_promotion_rules_taxons
    rename_table :friendly_condition_users, :friendly_promotion_rules_users
    rename_table :friendly_condition_products, :friendly_products_promotion_rules
    rename_column :friendly_promotion_rules_stores, :condition_id, :promotion_rule_id
    rename_column :friendly_promotion_rules_taxons, :condition_id, :promotion_rule_id
    rename_column :friendly_promotion_rules_users, :condition_id, :promotion_rule_id
    rename_column :friendly_products_promotion_rules, :condition_id, :promotion_rule_id

    solidus_sql = <<~SQL
      UPDATE friendly_promotion_rules
      SET type = REPLACE(type, 'SolidusFriendlyPromotions::Conditions', 'SolidusFriendlyPromotions::Rules')
    SQL
    execute(solidus_sql)

    cs_sql = <<~SQL
      UPDATE friendly_promotion_rules
      SET type = REPLACE(type, 'Cs::Promotion::Conditions', 'Cs::Promotion::Rules')
    SQL
    execute(cs_sql)
  end
end
