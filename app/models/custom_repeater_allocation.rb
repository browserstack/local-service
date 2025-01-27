class CustomRepeaterAllocation < ApplicationRecord
  belongs_to :repeater

  validates :user_or_group_id, presence: true
  validates :association_type, presence: true, inclusion: { in: %w[user group], message: "%{value} is not a valid association type" }
end
