class RepeaterIp < ApplicationRecord
  belongs_to :repeater

  validates :private_ip, presence: true, uniqueness: true, format: {
    with: /\A\d{1,3}(\.\d{1,3}){3}\z/,
    message: "Private IP must be a valid IPv4 address"
  }

  validates :public_ip, presence: true, uniqueness: true, format: {
    with: /\A\d{1,3}(\.\d{1,3}){3}\z/,
    message: "Public IP must be a valid IPv4 address"
  }
end
