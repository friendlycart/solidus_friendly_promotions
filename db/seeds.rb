SolidusFriendlyPromotions::PromotionGroup::GROUP_PRIORITY_NAMES.each_with_index do |group, index|
  SolidusFriendlyPromotions::PromotionGroup.find_or_create_by!(name: group, position: index)
end
