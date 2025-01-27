class TunnelRepeater < ApplicationRecord
  belongs_to :local_tunnel_info
  belongs_to :repeater

  validates :tunnel_id, presence: true
  validates :user_or_group_id, presence: true
  validates :association_type, presence: true, inclusion: { in: %w[user group], message: "%{value} is not a valid association type" }
end