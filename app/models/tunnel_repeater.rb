class TunnelRepeater < ApplicationRecord
  belongs_to :local_tunnel_info
  belongs_to :repeater

  validates :local_tunnel_info_id, presence: true
  validates :user_or_group_id, presence: true
  validates :association_type, presence: true, inclusion: { in: %w[user group], message: "%{value} is not a valid association type" }
  validates :disconnected, inclusion: { in: [true, false] }

  def mark_disconnected
    update(disconnected: true)
  end
 
  def reconnect
    update(disconnected: false)
  end
end
