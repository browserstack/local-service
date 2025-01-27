class RepeaterRegion < ApplicationRecord
  has_many :repeater_sub_regions, dependent: :destroy
  has_many :repeaters, dependent: :destroy

  validates :dc_name, presence: true, uniqueness: true
end
