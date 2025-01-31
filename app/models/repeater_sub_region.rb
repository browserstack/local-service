class RepeaterSubRegion < ApplicationRecord
  belongs_to :repeater_region
  has_many :repeater, dependent: :destroy

  validates :dc_name, presence: true, uniqueness: true
  validates :latitude, :longitude, presence: true
  validates :state, inclusion: { in: %w[up down partially_down], message: "%{value} is not a valid state" }
end
