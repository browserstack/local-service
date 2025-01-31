module RepeaterHelper

  def self.get_repeater_list(region, local_tunnel_info, user_id, group_id, sub_group_id, custom_repeater_params=nil)
    custom_repeaters_allotted = RedisUtils.allot_custom_repeaters?(user_id, group_id, sub_group_id)
    local_identifier = local_tunnel_info.local_identifier
    local_geolocation_enabled = !local_identifier.blank? && local_identifier.start_with?("local-ip-geolocation-")
    
    # ToDo -> See how the product is needed to be managed . Also see the constant correct usage
    product = "Unknown"

    if custom_repeaters_allotted
      # TODO -> potentially optimise this to not fetch custom_backup_repeater in case of local_geolocation_enabled
      custom_repeaters, custom_backup_repeater = RepeaterHelper.get_custom_repeaters(user_id, group_id, sub_group_id, region)
      tunnel_repeaters = custom_repeaters
      backup_map = tunnel_repeaters.map{ |rep| false }

      if local_geolocation_enabled
        tunnel_repeaters_for_region, backup_map = RepeaterHelper.get_repeater_region(region)
        tunnel_repeaters = tunnel_repeaters_for_region.select do |rep|
          custom_repeaters.any? { |custom_rep| custom_rep.host_name == rep.host_name }
        end
        if tunnel_repeaters.empty?
          tunnel_repeaters = tunnel_repeaters_for_region
        end
        return tunnel_repeaters, backup_map
      end
      
      if RedisUtils.region_blocked?(region) && !custom_backup_repeater.empty?
        backup_map = tunnel_repeaters.map { |rep| custom_backup_repeater.include?(rep.host_name) }
        backup_map = backup_map.presence || tunnel_repeaters.map { false }
        local_tunnel_info.backup_repeaters_address = tunnel_repeaters.map(&:host_name).join(",")
      end

      return tunnel_repeaters, backup_map
    end
    
    if local_tunnel_info.ats_local? || local_tunnel_info.integrations_service_local?
      tunnel_repeaters, backup_map = RepeaterHelper.get_ats_repeaters(region)
      Rails.logger.info("[LOCAL][Turboscale] Connecting binary to repeaters: #{tunnel_repeaters}")
      return tunnel_repeaters, backup_map
    end

    # ToDo -> See how to handle this call as this util is not here. API call or in parameter
    if RegionRestrictionUtils.check_georestricted_group(group_id, product)
      tunnel_repeaters, backup_map = RepeaterHelper.get_repeater_region(region, false, count=30)
      tunnel_repeaters.uniq!
      return tunnel_repeaters, backup_map
    end

    if custom_repeater_params
      custom_repeaters = custom_repeater_params.split(",").map(&:strip).uniq
    
      tunnel_repeaters = Repeater
        .joins(:custom_repeater_allocations)
        .where(<<-SQL.squish, user_id: user_id, group_id: group_id, sub_group_id: sub_group_id)
          (
            (custom_repeater_allocations.user_or_group_id = :user_id AND custom_repeater_allocations.association_type = 'user')
            OR
            (custom_repeater_allocations.user_or_group_id = :group_id AND custom_repeater_allocations.association_type = 'group')
            OR
            (custom_repeater_allocations.user_or_group_id = :sub_group_id AND custom_repeater_allocations.association_type = 'sub_group')
          )
        SQL
        .where(host_name: custom_repeaters)
        .select(:id, :host_name, :state)
        .distinct
    
      if tunnel_repeaters.empty?
        tunnel_repeaters, backup_map = RepeaterHelper.get_repeater_region(region)
      else
        backup_map = tunnel_repeaters.map { false }
      end
    
      return tunnel_repeaters, backup_map
    end
    

    local_hub_repeater_regions_for_user = LocalHubRepeaterRegions.get_repeater_hub_regions_for_user(user_id)
    if local_hub_repeater_regions_for_user && !JSON.parse(local_hub_repeater_regions_for_user.hub_repeater_sessions || "{}").empty?
      tunnel_repeaters, backup_map = RepeaterHelper.get_repeater_region(region, true, count=6)
      # Cross repeater allocation
      # Get hub_regions from local_hub_repeater_regions table and add repeaters from those regions
      hub_regions = JSON.parse(local_hub_repeater_regions_for_user.hub_repeater_sessions)
      hub_regions.keys.each do |hub_region|
        additional_repeaters, additional_backup_map = RepeaterHelper.get_repeater_region(hub_region, true, count=6)
        tunnel_repeaters |= additional_repeaters
        backup_map.concat(additional_backup_map)
      end
      Rails.logger.info("[LOCAL] Connecting binary to region: #{region}")
      Rails.logger.info("[LOCAL] Connecting binary to hub regions: #{hub_regions}")
    else
      tunnel_repeaters, backup_map = RepeaterHelper.get_repeater_region(region, true, count=30)
    end

    return tunnel_repeaters, backup_map
    # ToDo -> Handle russia-backup case, take case of user.country get it from parameter above itself
  end  

  
  #### Had created this function in our initial discussion am unable to find the relevance of it now.
  #### Let me know we the use of it still prevails !!
  def get_repeater_list_for_dummy_tunnel(region, user_id, group_id, sub_group_id, product, type)
  end 


  
  def self.get_ats_repeaters(region)
    if CONFIG[:env]['name'] == "production"
      # repeater table where check for type  = "ATS" . Also add get_filter wala logic in this query
      ats_repeaters = Repeater.where(repeater_type: 'ATS').select(:id, :host_name, :state)
      repeaters = self.filter_damaged_repeaters(ats_repeaters)
      backup_map = repeaters.map{ |rep| false }
      return repeaters, backup_map
    else
      return self.get_repeater_region(region)
    end
  end

  def self.get_repeater_region(region, use_backup=true, count=nil)
    repeater_region = region
    backup_map = []
    is_backup_used = false
        
    #  if reagion is down => we are using the  backup repeater in such case return a backup_map of all true else backup_map of all false.
    if (RedisUtils.region_blocked?(region) || RedisUtils.repeater_blocked?(region)) && use_backup
      # ToDo-> Add in constants. Copy relevant values from browser_extensions.yml?
      repeater_region =  BACKUP_REPEATERS[region]
      is_backup_used = true
    end

    # join with repeater_region table on the basis region_id
    # filter status that is = down , blacklist(fully)
    # select status, hostname, repeater_id
    repeater_details = Repeater.joins(:repeater_regions).where(repeater_regions: { dc_name: repeater_region }).where.not(state: ["down", "blacklisted"]).select(:id, :host_name, :state)

    repeaters = self.filter_damaged_repeaters(repeater_details)

    if !count.nil? && repeaters.size > count
      dcp_repeaters = repeaters.select { |rep| rep.host_name.include?('dcp') }
      ec2_repeaters = repeaters.reject { |rep| rep.host_name.include?('dcp') }

      dcp_repeaters = dcp_repeaters.sample(count/2)
      ec2_repeaters = ec2_repeaters.sample(count/2)
      return dcp_repeaters + ec2_repeaters
    end

    backup_map = repeaters.map{ |rep| is_backup_used }

    return repeaters, backup_map
  end

  def self.get_custom_repeaters(user_id, group_id, sub_group_id, region)
    # call custom repeater allocation table and get the custom_repeater from it. 
    #  write a query to fetch the repeater id . On the basis of user_or_group_id and its association type
    #  get the whole partiall balcklisted wala filer_damaged_repeater logic from table as done above 

    custom_repeater_details = CustomRepeaterAllocation
      .joins(:repeaters)
      .where(
        <<-SQL.squish,
          (
            (user_or_group_id = :user_id AND association_type = 'user') OR
            (user_or_group_id = :group_id AND association_type = 'group') OR
            (user_or_group_id = :sub_group_id AND association_type = 'sub_group')
          )
        SQL
        user_id: user_id, group_id: group_id, sub_group_id: sub_group_id
      )
      .where.not(repeaters: { state: ["down", "blacklisted"] })
      .select(
        "repeaters.id",
        "repeaters.host_name",
        "repeaters.state",
        "custom_repeater_allocations.allocation_type AS allocation_type"
      )

      desktop_rows = custom_repeater_details.select { |r| r.allocation_type == 'desktop' }
      backup_rows  = custom_repeater_details.select { |r| r.allocation_type == 'backup' }

    repeaters = if RedisUtils.region_blocked?(region)
                  backup_rows.presence || desktop_rows
                else
                  desktop_rows
                end

    repeaters = self.filter_damaged_repeaters(repeaters)
    if repeaters.nil? || repeaters.count == 0
      Rails.logger.info("[TunnelLog] User #{user_id} all the custom repeaters are blacklisted or markeddown")
      # ToDo -> See how to handle this call as util is not here
      Util.send_to_pager('no-custom-repeaters-available', {:timestamp => Time.now.to_i, :user_id => user_id, :group_id => group_id, :sub_group_id => sub_group_id, :region => region})
    end

    tunnel_repeaters = repeaters

    has_custom_backup_repeaters = RedisUtils.get_custom_repeaters(user_id, group_id, sub_group_id, 'backup').present?
    if has_custom_backup_repeaters
      backup_repeaters = RedisUtils.get_custom_repeaters(user_id, group_id, sub_group_id, 'backup')
    end

    return tunnel_repeaters, backup_repeaters
  end


  def self.filter_damaged_repeaters(repeaters)
    return [] if repeaters.nil?

    up_repeaters = repeaters.select { |rep| rep.state == "up" }
    partial_blacklisted_repeaters = repeaters.select { |rep| rep.state == "partially_blacklisted" } || []

    final_repeaters = up_repeaters.any? ? up_repeaters : partial_blacklisted_repeaters

    return final_repeaters
  end
end