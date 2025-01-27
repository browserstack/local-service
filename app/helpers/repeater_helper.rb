module RepeaterHelper

  def get_repeater_list(region, custom_repeater_params, geopolitical_region, local_tunnel_info, user_id, group_id, sub_group_id, product, type)
    custom_repeaters_allotted = RedisUtils.allot_custom_repeaters?(user_id, group_id, sub_group_id)
    local_geolocation_enabled = !local_identifier.blank? && local_identifier.start_with?("local-ip-geolocation-")
    product = IS_APP_AUTOMATE ? APP_AUTOMATE : AUTOMATE

    if custom_repeaters_allotted
      # TODO -> potentially optimise this to not fetch custom_backup_repeater in case of local_geolocation_enabled
      repeaters, custom_backup_repeater = RepeaterHelper.get_custom_repeaters(user_id, group_id, sub_group_id, region)
      tunnel_repeaters = []
      backup_map = []

      if local_geolocation_enabled
        tunnel_repeaters_for_region, backup_map = RepeaterHelper.get_repeater_region(region)
        tunnel_repeaters = tunnel_repeaters_for_region & repeaters
        if tunnel_repeaters.empty?
          tunnel_repeaters = tunnel_repeaters_for_region
        end
        return tunnel_repeaters, backup_map
      end
      
      local_tunnel_info.backup_repeaters_address = tunnel_repeaters.join(",")
      if RedisUtils.region_blocked?(region) && !custom_backup_repeater.empty?
        backup_map = tunnel_repeaters.map{ |rep| backup_repeaters.include?(rep) }
      end

      return tunnel_repeaters, backup_map
    end
    
    if local_tunnel_info.ats_local? || local_tunnel_info.integrations_service_local?
      tunnel_repeaters, backup_map = RepeaterHelper.get_ats_repeaters(region)
      custom_repeaters_allotted = true
      Rails.logger.info("[LOCAL][Turboscale] Connecting binary to repeaters: #{tunnel_repeaters}")
      return tunnel_repeaters, backup_map
    end

    if RegionRestrictionUtils.check_georestricted_group(group_id, product)
      tunnel_repeaters, backup_map = RepeaterHelper.get_repeater_region(region, false, count=30)
      tunnel_repeaters.uniq!
      return tunnel_repeaters, backup_map
    end

    if custom_repeater_params
      # check if the all the custom repeaters are present in the DB  
    end

    # Create a table same as LocalHubRepeaterRegions from railsApp
    # ToDo -> create a jira task to migrate LocalHubRepeaterRegions from railsApp to Local-service

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
    if RedisUtils.region_blocked?(region)
      backup_map = tunnel_repeaters.map{ |rep| CHROME_REPEATERS[BACKUP_REPEATERS[region]].include?(rep) }
    end

    # ToDo -> Handle russia-backup case 
    # ToDO -> Else sceneroi handle hub region if no region is passed for L -127(railsApp)
  end  

  def get_repeater_list_for_dummy_tunnel(region, user_id, group_id, sub_group_id, product, type)

  end 
  
  def self.get_ats_repeaters(region)
    if CONFIG[:env]['name'] == "production"
      # repeater table where check for type  = "ATS" . Also add get_filter wala logic in this query
      ats_repeaters = Repeater.where(repeater_type: 'ATS').select(:id, :state)
      repeaters = self.filter_damaged_repeaters(ats_repeaters)
      backup_map = tunnel_repeaters.map{ |rep| true }
      return repeaters, backup_map
    else
      return self.get_repeater_region(region)
    end
  end


  def self.get_repeater_region(region, use_backup=true, count=nil)
    repeater_region = region
    backup_map = []
    #  if reagion is down => we are using the  backup repeater in such case return a backup_map of all true else backup_map of all false.
    if (RedisUtils.region_blocked?(region) || RedisUtils.repeater_blocked?(region)) && use_backup
      repeater_region =  BACKUP_REPEATERS[region]
      backup_map = tunnel_repeaters.map{ |rep| true }
    end

    # join with repeater_region table on the basis region_id
    # filter status that is = down , blacklist(fully)
    # select status, hostname, repeater_id
    repeater_details = Repeater.joins(:repeater_region).where(repeater_regions: { dc_name: repeater_region }).where.not(state: ["Down", "blacklisted"]).select(:id, :host_name, :state)

    # remove partial blacklist repeater if there is atlaest one repeater with status = up
    repeaters = self.filter_damaged_repeaters(repeater_details)

    if !count.nil? && repeaters.size > count
      # dcp_repeaters, ec2_repeaters = LocalUtility.filter_repeaters(repeaters)
      dcp_repeaters = final_repeaters.select { |rep| rep.host_name.include?('dcp') }
      ec2_repeaters = final_repeaters.reject { |rep| rep.host_name.include?('dcp') }

      dcp_repeaters = dcp_repeaters.sample(count/2)
      ec2_repeaters = ec2_repeaters.sample(count/2)
      return dcp_repeaters + ec2_repeaters
    end
    backup_map = tunnel_repeaters.map{ |rep| false }

    return repeaters, backup_map
  end

  # TODO -: write migration script to populate custom repeater allocation table from redis.

  def self.get_custom_repeaters(user_id, group_id, sub_group_id, region)
    # custom_repeaters = RedisUtils.get_custom_repeaters(user_id, group_id, sub_group_id, 'desktop')
     # call custom repeater allocation table and get the custom_repeater from it. 
    #  write a query to fetch the repeater id . On the basis of user_or_group_id and its association type
    #  get the whole partiall balcklisted wala filer_damaged_repeater logic from table as done above 

    custom_repeater_details = CustomRepeaterAllocation
      .joins(:repeater)
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
      .where.not(repeaters: { state: ["Down", "Blacklisted"] })
      .select(
        "repeaters.id AS repeater_id",
        "repeaters.state",
        "custom_repeater_allocations.allocation_type AS allocation_type"
      )

      custom_repeaters = custom_repeater_details.select { |record| record.allocation_type == 'desktop' }.map(&:repeater_id)
      backup_repeaters = [] 

    repeaters = if RedisUtils.region_blocked?(region)
                  #  backup repeater = above query response 
                  # backup_repeaters = RedisUtils.get_custom_repeaters(user_id, group_id, sub_group_id, 'backup')
                  backup_repeaters = custom_repeater_details.select { |record| record.allocation_type == 'backup' }.map(&:repeater_id)
                  backup_repeaters.presence || custom_repeaters
                else
                  custom_repeaters
                end
    # handled in above query same!1 
    repeaters = self.filter_damaged_repeaters(repeaters)
    if repeaters.nil? || repeaters.count == 0
      Rails.logger.info("[TunnelLog] User #{user_id} all the custom repeaters are blacklisted or markeddown")
      Util.send_to_pager('no-custom-repeaters-available', {:timestamp => Time.now.to_i, :user_id => user_id, :group_id => group_id, :sub_group_id => sub_group_id, :region => region})
    end

    custom_repeaters.uniq!
    tunnel_repeaters = custom_repeaters
    has_custom_backup_repeaters = RedisUtils.get_custom_repeaters(user_id, group_id, sub_group_id, 'backup').present?
    backup_repeaters = RedisUtils.get_custom_repeaters(user_id, group_id, sub_group_id, 'backup')

    return repeaters, backup_repeaters
  end


  def self.filter_damaged_repeaters(repeaters)
    return [] if repeaters.nil?

    up_repeaters = repeaters.select { |rep| rep.state == "up" } || []
    partial_blacklisted_repeaters = repeaters.select { |rep| rep.state == "partially_blacklisted" } || []

    final_repeaters = up_repeaters.any? ? up_repeaters : partial_blacklisted_repeaters

    final_repeaters
  end
end