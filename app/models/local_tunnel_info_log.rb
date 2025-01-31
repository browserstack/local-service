class LocalTunnelInfoLog < ApplicationRecord
  belongs_to :local_tunnel_info

  SALT = "DFs1V&@{$*df(YBvdsv)}234DSB%$bid"

  validates :hashed_id, presence: true, uniqueness: true
  validates :auth_token, presence: true
  validates :local_tunnel_info_id, presence: true
  validates :user_or_group_id, presence: true
  validates :association_type, presence: true, inclusion: { in: %w[user group] }
  validates :json_version, presence: true

  def self.create_with_params(local_tunnel_info, cmd_line_params, system_details, misc_data, display)
    system_details[:private_ip] = filter_local_ips(system_details[:private_ip])
    LocalTunnelInfoLog.create!(
      local_tunnel_info_id: local_tunnel_info.id,
      params: cmd_line_params,
      user_or_group_id: local_tunnel_info.user_or_group_id, 
      association_type: local_tunnel_info.association_type,
      auth_token: local_tunnel_info.auth_token,
      system_details: system_details.to_json,
      local_identifier: local_tunnel_info.local_identifier,
      hashed_id: Digest::SHA1.hexdigest("--#{SALT}-%%-#{local_tunnel_info.id}--"),
      json_version: LOCAL_CONSTANTS['json_version'],
      misc_data: misc_data,
      display: display
    )
  end

  def self.filter_local_ips(ips)
    return {} if ips.blank?

    ips = JSON.parse(ips)
    ip_arr = []
    ips.each do |interface, ip_list|
      ip_list.each do |ip|
        next if ip.match(/127\.\d+\.\d+\.\d+/) && ip.match(":").nil?
        next if ip == "::1"
        ip_arr << ip.to_s.strip
      end
    end

    ip_arr
  end
end
