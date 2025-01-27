class Repeater < ApplicationRecord
  belongs_to :repeater_region
  belongs_to :repeater_sub_region
  has_many :repeater_ips, dependent: :destroy

  validates :host_name, presence: true, uniqueness: true, format: {
    with: /\Arepeater-local-(\d+)-(dcp|ec2)-([a-zA-Z0-9]{5,})-prod\.browserstack\.com\z/,
    message: "Repeater host_name is invalid. Hostname should match the expected format."
  }
  validates :state, inclusion: { in: %w[active inactive down] }
  validates :repeater_type, presence: true, inclusion: { in: %w[custom dedicated_ip general_dc general_aws] }
end
