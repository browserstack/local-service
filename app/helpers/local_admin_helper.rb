module LocalAdminHelper

  def get_custom_repeater_for_scope(type, scope)
    raise StandardError.new("Scope is not in user, sub_group, group") unless %w(user sub_group group).include?(scope)
    raise StandardError.new("Type is not in desktop, backup") unless %w(desktop backup).include?(type)
    allocations = CustomRepeaterAllocation
      .where(association_type: scope, allocation_type: type)
      .pluck("user_or_group_id", "repeaters.id")
  
    grouped = allocations.group_by(&:first)
    grouped.transform_values { |rows| rows.map(&:last) }
  end

  def modify_desktop_custom_repeater(action, scope, id, repeater_id)
    raise StandardError.new("Action is not in add, remove") unless %w(add remove).include?(action)
    raise StandardError.new("Scope is not in user, sub_group, group") unless %w(user sub_group group).include?(scope)
    raise StandardError.new("Id should be present") if id.blank?
  
    case action
    when "add"
      allocation = CustomRepeaterAllocation.find_or_create_by!(
        user_or_group_id:  id,
        association_type:  scope,
        allocation_type:   "desktop",
        repeater_id:       repeater_id
      )
      return "Added repeater #{repeater_id} for #{scope}_id #{id}"
  
    when "remove"
      CustomRepeaterAllocation
        .where(
          user_or_group_id:  id,
          association_type:  scope,
          allocation_type:   "desktop",
          repeater_id:       repeater_id
        )
        .delete_all
      return "Removed repeater #{repeater_id} for #{scope}_id #{id}"
    end

    def self.blacklist_repeater(repeater_hostname)
      Repeater.where(host_name: repeater_hostname).update_all(state: 'blacklisted')
    end
    
    def self.partial_blacklist_repeater(repeater_hostname)
      Repeater.where(host_name: repeater_hostname).update_all(state: 'partial_blacklisted')
    end

  end

  



  


end