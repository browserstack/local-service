class LocalHubRepeaterRegion < ApplicationRecord
  validates :user_or_group_id, presence: true
  validates :association_type, presence: true, inclusion: { in: %w[user group], message: "%{value} is not a valid association type" }

  def self.save_to_local_hub_repeater_regions(user_or_group_id, association_type= 'user', hub_repeater_sessions_str)
    create(user_or_group_id: user_or_group_id, association_type: association_type, hub_repeater_sessions: hub_repeater_sessions_str)
  end

  def self.delete_all_data
    LocalHubRepeaterRegions.delete_all
  end

  def self.get_repeater_hub_regions_for_user_or_group(user_or_group_id, association_type = 'user')
    find_by(user_or_group_id: user_or_group_id, association_type: association_type)
  end
end