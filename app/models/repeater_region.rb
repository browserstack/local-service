class RepeaterRegion < ApplicationRecord
  has_many :repeater_sub_region, dependent: :destroy
  has_many :repeater, dependent: :destroy

  validates :dc_name, presence: true, uniqueness: true
end
