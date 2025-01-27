class LocalTunnelInfo < ApplicationRecord
  has_many :tunnel_repeaters
  has_many :repeaters, through: :tunnel_repeaters

  validates :auth_token, presence: true, uniqueness: true
  validates :local_identifier, presence: true
  validates :hashed_identifier, presence: true, uniqueness: true
  validates :region, presence: true
  validates :proxy_type, presence: true
  validates :tunnel_type, presence: true
end