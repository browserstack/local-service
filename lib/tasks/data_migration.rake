namespace :migration do
  desc "Migrate data from LicencePoolOld to LicencePool"
  task licence_pools: :environment do |task|
    class LicencePoolOld < ApplicationRecord
      self.table_name = 'licence_pools'
      establish_connection(RAILS_APP_DB)
    end

    begin
      DataMigrationUtils.migrate_data(
        old_model: LicencePoolOld,
        new_model: LicencePool,
        column_mapping: lambda { |old_record|
          {
            username: old_record.username,
            password: old_record.password,
            group_id: old_record.group_id,
            ready_for_allocation_at: old_record.ready_for_allocation_at,
            common_licence: old_record.common_licence,
            created_at: old_record.created_at,
            updated_at: old_record.updated_at
          }
        },
        task: task
      )
    rescue StandardError => e
      RakeLogger.log "Error migrating LicencePool data: #{e.message}" 
    ensure
      LicencePoolOld.connection_pool.disconnect!
    end
  end

  desc "Migrate data from LicencePoolVersionOld to LicencePoolVersion"
  task licence_pool_versions: :environment do |task|
    class LicencePoolVersionOld < ApplicationRecord
      self.table_name = 'licence_pool_versions'
      establish_connection(RAILS_APP_DB)
    end

    DataMigrationUtils.migrate_data(
      old_model: LicencePoolVersionOld,
      new_model: LicencePoolVersion,
      column_mapping: lambda { |old_record|
        {
          item_type: old_record.item_type,
          item_id: old_record.item_id,
          event: old_record.event,
          prev_group_id: old_record.prev_group_id,
          new_group_id: old_record.new_group_id,
          whodunnit: old_record.whodunnit,
          object: old_record.object,
          created_at: old_record.created_at
        }
      },
      task: task
    )
  end

  # Task for migrating LocalGlobalSettingOld to LocalGlobalSetting
  desc "Migrate data from LocalGlobalSettingOld to LocalGlobalSetting"
  task local_global_settings: :environment do |task|
    class LocalGlobalSettingsOld < ApplicationRecord
      self.table_name = 'local_global_settings'
      establish_connection(RAILS_APP_DB)
    end

    DataMigrationUtils.migrate_data(
      old_model: LocalGlobalSettingOld,
      new_model: LocalGlobalSetting,
      column_mapping: lambda { |old_record|
        {
          setting_id: old_record.setting_id,
          setting_type: old_record.setting_type,
          property_key: old_record.property_key,
          property_value: old_record.property_value,
          property_type: old_record.property_type
        }
      },
      task: task
    )
  end
end
