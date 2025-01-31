class RedisUtils
  def allot_custom_repeaters?(user_id, group_id, sub_group_id)
    return (DEFAULT_REDIS_CLIENT.sismember('custom_repeaters_user_id_hash', user_id) ||
      DEFAULT_REDIS_CLIENT.sismember('custom_repeaters_group_id_hash', group_id) ||
      DEFAULT_REDIS_CLIENT.sismember('custom_repeaters_sub_group_id_hash', sub_group_id))
  end

  # @param type [String] can be one of ["desktop", "backup"]. "mobile" is deprecated
  def get_custom_repeaters(user_id, group_id, sub_group_id, type)
    user_repeaters = DEFAULT_REDIS_CLIENT.smembers("custom_#{type}_repeaters_for_user_#{user_id}")
    return user_repeaters unless user_repeaters.empty?
    sub_group_repeaters = DEFAULT_REDIS_CLIENT.smembers("custom_#{type}_repeaters_for_sub_group_#{sub_group_id}")
    return sub_group_repeaters unless sub_group_repeaters.empty?

    DEFAULT_REDIS_CLIENT.smembers("custom_#{type}_repeaters_for_group_#{group_id}")
  end

  def self.region_blocked?(region)
    regions_to_check = _compute_regions_to_process(region)
    regions_to_check.each do |region_to_check|
      if TERMINAL_CLEANUP_REDIS_CLIENT.sismember('block_region', region_to_check)
        return true
      end
    end
    return false
  end

  def self.repeater_blocked?(region)
    DEFAULT_REDIS_CLIENT.sismember('block_repeater', region)
  end

  def self.get_selenium_region(key)
    DEFAULT_REDIS_CLIENT.get("selenium_region_#{key}")
  end

  def self.local_debugging_enabled?(user_id)
    DEFAULT_REDIS_CLIENT.get("local_debug_#{user_id}").to_s == "true"
  end

  def self.get_non_ssl_protocol_for_local
    DEFAULT_REDIS_CLIENT.lrange('non_ssl_protocol_for_local', 0, -1) #['ws', 'http']
  end

  def self.allow_non_ssl_protocol_for_local?(group_id, user_id)
    DEFAULT_REDIS_CLIENT.sismember('non_ssl_protocol_for_local_user_id_hash', user_id) || DEFAULT_REDIS_CLIENT.sismember('non_ssl_protocol_for_local_group_id_hash', group_id)
  end

  def self.get_custom_terminal_socket_timeout(user_id, group_id)
    DEFAULT_REDIS_CLIENT.hget('custom_terminal_socket_timeout_for_user', user_id) || DEFAULT_REDIS_CLIENT.hget('custom_terminal_socket_timeout_for_group', group_id)
  end

end