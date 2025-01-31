class ProxyController < ApplicationController

  def port
    if !['chrome', 'firefox', 'node'].include?(params[:tunnel])
      create_user_activity_log({
        :activity_type => "Jar Log",
        :data => "Returned request from JAR"
      })
      head 403
      return
    end

    region = RedisUtils.get_selenium_region("group_id_#{@current_user.group_id}") || @user_region

    if params[:force_create].to_s == "true"
      # Local Geolocation: Select repeaters based on requested geolocation region.
      region = @user_region
    end
    geo_restricted_region_map = {
      "us": "us-east-1",
      "eu": "eu-west-1",
      "in": "ap-south-1"
    }
    
    @geopolitical_region = RegionRestrictionUtils.check_georestricted_group(@current_user.group_id)
    if !@geopolitical_region.nil?
      region = geo_restricted_region_map[@geopolitical_region.to_sym]
    end
    new_local_tunnel_info_obj, tunnel_repeaters, backup_map, global_settings_applied = initialize_local_tunnel_info(region, @token)

    if tunnel_repeaters.empty? 
      render :json => { :browserstack_message => "Error: Could not setup Local Testing.", :no_repeaters_alloted => true }.to_json, :status => 503
      return
    end

    sameVersion, latestVersion = check_for_version_update
    begin
      if params[:tunnel] == 'node' && !sameVersion && params[:version] > 3.91
        old_identifier = [new_local_tunnel_info_obj.local_identifier, "oldBinary"].select {|x| !x.to_s.empty?}.join("-")
        new_local_tunnel_info_obj.update_local_identifier_attribute("#{@token}-oldBinary", false)
        LocalTunnelInfo.destroy_by_token("#{@token}-oldBinary")
        new_local_tunnel_info_obj.save!
      else
        if params[:tunnel] == 'node'
          LocalTunnelInfo.destroy_by_token("#{@token}-oldBinary")
        end

        local_tunnel_info_obj = LocalTunnelInfo.find_by_token(@token)
        if params[:dummy_tunnel]
          begin
            if !local_tunnel_info_obj.blank?
              render :json => { status: "Dummy tunnel already exists" }.to_json, :status => 200
              return
            end
            is_saved = new_local_tunnel_info_obj.safely_save
          rescue ActiveRecord::RecordNotUnique=>e
            Rails.logger.info "Got RecordNotUnique exception saving dummy LTI - #{@token} - #{new_local_tunnel_info_obj[:hashed_identifier]}, returning 200 so existing tunnel can be picked up"
            render :json => { status: "Dummy tunnel already exists" }.to_json, :status => 200
            return
          end
        else
          backup_repeaters_address_lti = local_tunnel_info_obj && local_tunnel_info_obj.backup_repeaters_address
          local_tunnel_info_obj.destroy rescue nil
          new_local_tunnel_info_obj.backup_repeaters_address = backup_repeaters_address_lti if backup_repeaters_address_lti
          is_saved = new_local_tunnel_info_obj.safely_save
        end
        unless is_saved
          render :json => { :browserstack_message => "Error: Could not setup Local Testing." }.to_json, :status => 503
          return
        end
        system_details = {
          :public_ip  => get_user_ip,
        }
        enabled_by_user = false
        if (params[:cmdLineParams])
          if params[:debug_params]
            if !RedisUtils.local_debugging_enabled?(current_user.id)
              render :json => { :browserstack_message => "Debug utility is not enabled for you. Please contact support@browserstack.com to enable this feature." }.to_json, :status => 403
              return
            else
              misc_data = { :debug_data => params[:debug_params] }.to_json
            end
          end

          identifier = @token.split('-', 2)[1].to_s
          enabled_by_user = identifier.match(/^browserstack-fork-\d+$/).present? ? false : true
          system_details.merge!({ :private_ip => params[:localIPs] })
          system_details.merge!(JSON.parse(params[:systemParams]))

          lti_log = LocalTunnelInfoLog.create_with_params(new_local_tunnel_info_obj, params[:cmdLineParams], system_details, misc_data, enabled_by_user)
          
        end
      end
    rescue ActiveRecord::RecordNotUnique=>e
      Rails.logger.info "Got RecordNotUnique excpetion while saving LTI - #{@token} - #{new_local_tunnel_info_obj[:hashed_identifier]}: #{e.message} and stack trace: #{e.backtrace.join('\n')}"
      render :json => { :browserstack_message => "Error: Could not setup Local Testing." }.to_json, :status => 403
      return
    end
    new_local_tunnel_info_obj.initialize_tunnel_repeaters(tunnel_repeaters, backup_map, current_user.id)
    local_tunnel_servers = new_local_tunnel_info_obj.get_tunnel_servers
    o_hash = {
      :name              => (new_local_tunnel_info_obj.username || "").downcase,
      :tunnelHostServer  => nil,
      :tunnelHostServers => local_tunnel_servers,
      :backupRepeaters   => new_local_tunnel_info_obj.alive_local_tunnel_repeaters.map{|r| r.backup},
      :versionUpdate     => (!sameVersion).to_s,
      :latestVersion     => latestVersion,
      :type_of_tunnel    => @type_of_tunnel.to_s,
      :port              => [['0']],
      :wsPort            => CONFIG[:chrome_extension]['ws_port'],
      :wssPort           => CONFIG[:chrome_extension]['wss_port'],
      :region            => region,
      :user_id           => @current_user.id.to_s,
      :info_log_id       => lti_log.try!(:hashed_id),
      :cls_log_url       => CONFIG[:central_log]["local_log_server"],
      :user_token        => @token,
      :full_name         => @current_user.full_name.to_s,
      :lti_id            => new_local_tunnel_info_obj.id,
      :group_id          => @current_user.group_id.to_s,
      :analytic_interval_time => BINARY_ANALYTIC_POSTBACK_TIME,
      :send_analytic_init => BINARY_ANALYTIC_INIT_POSTBACK,
      :global_settings_applied => global_settings_applied,
    }
    # Added dummy port for now
    unless params[:tunnel].blank?
      o_hash[:protocolSequence] = LOCAL_PROTOCOL_SEQUENCE
      o_hash[:protocolSequence] = RedisUtils.get_non_ssl_protocol_for_local if RedisUtils.allow_non_ssl_protocol_for_local?(@current_user.group_id, @current_user.id)
    end
    # Add deprecation warning if version deprecation is near
    if is_scheduled_for_deprecation?
      o_hash[:deprecation_message] = I18n.t('local_testing.deprecation.warning')
    end

    if @is_binary_deprecated
      LocalTunnelInfo.destroy_by_token(@token)
      o_hash[:tunnelHostServers] = []
      o_hash[:deprecation_message] = I18n.t('local_testing.deprecation.error')
    end

    custom_socket_timeout = RedisUtils.get_custom_terminal_socket_timeout(@current_user.id, @current_user.group_id)
    if custom_socket_timeout
      o_hash[:custom_socket_timeout] = custom_socket_timeout
    end

    tunnel_terminal_token = new_local_tunnel_info_obj.tunnel_terminal_token
    # ToDo ->  Create an API in railsApp
    # automate_session_ids = Tunnel.get_running_sessions('automate_logs', tunnel_terminal_token)
    # app_automate_session_ids = Tunnel.get_running_sessions( 'app_automate_logs', tunnel_terminal_token)

    if !(automate_session_ids.empty? && app_automate_session_ids.empty?)
      session_ids = Hash.new([])
      session_ids["automate_session_ids"] = automate_session_ids
      session_ids["app_automate_session_ids"] = app_automate_session_ids
      # using strings in hash instead of sym for sidekiq compatibility
      info = {"request_type" => "/proxy/port", "called_from" => "CONNECTION_INIT"}

      # ToDo -> Analyze this dependency here is it requires or to be removed 
      # LocalInitConnectionWorker.perform_async(session_ids, @token, @current_user.id, @current_user.group_id, info)
      
    end

    Tunnel.release_block_from_session_lock(@token)

    info_json = params[:cmdLineArgs] || params[:infoJson]

    # ToDo -> Sending data to EDS, Needed to be changes its not present here 
    # Tunnel.send_local_tunnel_info_eds(new_local_tunnel_info_obj, @current_user, info_json,  params[:semanticVersion])

    render :json => o_hash.to_json
  
  end
  
  
  def initialize_local_tunnel_info(region, token)
    local_tunnel_info = LocalTunnelInfo.create_by_token(token)
    local_tunnel_info.region = region
    tunnel_repeaters, backup_map = RepeaterHelper.get_repeater_list(region, local_tunnel_info, current_user.id, current_user.group_id, current_user.sub_group_id, params[:customRepeater])
    global_settings_applied = {}
    begin
      global_settings_applied = LocalGlobalSettings.get_all_local_global_settings(current_user)[:all_settings]
    rescue Exception => e
      Rails.logger.info("[LOCAL] Unable to get global settings for user: #{current_user.id} - #{e.message} - #{e.backtrace}")
    end

    local_tunnel_info.tunnel_type = params[:tunnel]
    proxy_type = params[:proxy_type] || "node"
    local_tunnel_info.proxy_type = proxy_type
    local_tunnel_info.version = params[:version]
    local_tunnel_info.host_only = params[:host_only]
    local_tunnel_info.force_local = (!params[:dummy_tunnel] && global_settings_applied["force_local"]) || params[:force_local]
    local_tunnel_info.user_id = current_user.try!(:id)
    local_tunnel_info.set_include_hosts(params[:include_hosts].to_s, global_settings_applied)
    local_tunnel_info.set_exclude_hosts(params[:exclude_hosts].to_s, global_settings_applied)
    local_tunnel_info.set_server_details(params[:hostports])

    local_tunnel_info.rotation_counter = 0
    local_tunnel_info.rotation_limit = tunnel_repeaters.length
    local_tunnel_info.username = current_user.username.to_s

    if params[:localServer] == "1"
      local_tunnel_info.server_hosts = "#{local_tunnel_info.username}.browserstack.com"
      local_tunnel_info.server_ports = "80"
    end

    local_tunnel_info.setup_time = Time.now

    return [local_tunnel_info, tunnel_repeaters, backup_map, global_settings_applied]

  end

  def check_for_version_update
    sameVersion, latestVersion = true, NODE_CMD_LINE_TUNNEL_VERSION
    params[:version] = (params[:version] || "1.0").to_f

    if params[:tunnel] == 'node'
      sameVersion = (params[:version] >= (NODE_CMD_LINE_TUNNEL_VERSION - 0.2))
      latestVersion = NODE_CMD_LINE_TUNNEL_VERSION
    else
      sameVersion = (params[:version] == CMD_LINE_TUNNEL_VERSION)
      latestVersion = CMD_LINE_TUNNEL_VERSION
    end

    if @token.match(/browserstack-fork-\d+$/) || params[:skipVersionUpdate] == "true"
      sameVersion = true
    end

    return sameVersion, latestVersion
  end

  def is_scheduled_for_deprecation?
    binary_version = (params[:version] || "1.0").to_f

    if params[:tunnel] && params[:tunnel] === 'node' && binary_version == NODE_CMD_LINE_TUNNEL_VERSION - 0.2
      Rails.logger.info("[Local] #{@token} - Showing warning for the scheduled deprecation #{binary_version}")
      return true
    end
    return false
  end
end
