class LocalTunnelInfo < ApplicationRecord
  MAX_SAVE_RETRIES = 5

  has_many :tunnel_repeaters
  has_many :repeaters, through: :tunnel_repeaters

  validates :auth_token, presence: true, uniqueness: true
  validates :local_identifier, presence: true
  validates :hashed_identifier, presence: true, uniqueness: true
  validates :region, presence: true
  validates :proxy_type, presence: true
  validates :tunnel_type, presence: true

  def self.create_by_token(token)
    auth_token, local_identifier = get_token_bits(token)
    hashed_identifier = get_hashed_identifier(local_identifier)
    LocalTunnelInfo.new :auth_token => auth_token, :hashed_identifier => hashed_identifier, :local_identifier => local_identifier
  end

  def update_local_identifier_attribute(token, save = true)
    auth_token, local_identifier = LocalTunnelInfo.get_token_bits(token)
    hashed_identifier = LocalTunnelInfo.get_hashed_identifier(local_identifier)
    self.hashed_identifier = hashed_identifier
    self.local_identifier = local_identifier
    self.save! if save
  end

  def safely_save(retries=0)
    begin
      self.save!
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.info("[LTI_SAVE_EXCEPTION] Exception on retry #{retries} #{e.message} #{e.backtrace}")
      raise e
    rescue ActiveRecord::StatementInvalid => e
      Rails.logger.info("[LTI_SAVE_EXCEPTION] Exception on retry #{retries} #{e.message} #{e.backtrace}")
      if retries == LocalTunnelInfo::MAX_SAVE_RETRIES
        return false
      end
      self.safely_save(retries + 1)
    end
  end

  def self.find_by_token(token, include_automate_dummy_tunnel=true)
    return nil if !token.present?
    auth_token, local_identifier = get_token_bits(token)
    hashed_identifier = get_hashed_identifier(local_identifier)
    ltis = LocalTunnelInfo.where(:auth_token => auth_token, :hashed_identifier => hashed_identifier)
    if !include_automate_dummy_tunnel
      # All dummy tunnels except automate dummy tunnel has local_identifier set, so we remove empty value from result.
      ltis = ltis.where.not("version = ? AND hashed_identifier = ?", NODE_CMD_LINE_TUNNEL_VERSION, get_hashed_identifier(""))
    end
    ltis.first
  end

  def initialize_tunnel_repeaters(repeaters_list, backups_list, user_id)
    tunnel_repeaters_dump = []
    repeaters_list.zip(backups_list).each do |repeater_id, backup|
      current_datetime = DateTime.now.utc.to_s
      # Added user id here was not being passed originally.
      repeater_hash = { :repeater => repeater_id, :tunnel_id => self.id, :user_or_group_id => user_id, :association_type => 'user',
                        :backup => backup, :created_at => current_datetime, :updated_at => current_datetime }
      tunnel_repeaters_dump.append(repeater_hash)
    end
    tunnel_repeaters = TunnelRepeater.insert_all!(tunnel_repeaters_dump)
  end

  def self.destroy_by_token(token)
    auth_token, local_identifier = get_token_bits(token)
    hashed_identifier = get_hashed_identifier(local_identifier)
    LocalTunnelInfo.where(:auth_token => auth_token, :hashed_identifier => hashed_identifier).first.destroy rescue nil
  end

  def self.get_token_bits(token)
    token_bits = token.split("-")
    auth_token = token_bits.slice!(0)
    local_identifier = token_bits.join("-")
    return [auth_token, local_identifier]
  end

  def self.get_hashed_identifier(local_identifier)
    Digest::SHA1.hexdigest(local_identifier)
  end
end
