module DataMigrationUtils

   def self.migrate_data(old_model:, new_model:, column_mapping:, use_redis: false, task:)
    start_time = Time.now
    redis_key = new_model.to_s

    batch_size = RedisUtils.get_migration_table_batch_size(redis_key) || 1000
    
    RakeLogger.log("Starting migration for #{old_model} to #{new_model} with batch size of #{batch_size} with redis: #{use_redis}", task)
    old_model.find_in_batches(batch_size: batch_size).with_index(1) do |batch, batch_index|
      records_to_insert = []
      if use_redis
        batch.each do |old_record|
          next if RedisUtils.already_migrated?(redis_key, old_record.id)
          records_to_insert << column_mapping.call(old_record)
        end
      else
        batch.each do |old_record|
          records_to_insert << column_mapping.call(old_record)
        end
      end
      
      if records_to_insert.any?
        new_model.insert_all(records_to_insert)
        if use_redis
          batch.each { |record| RedisUtils.store_migration_record(redis_key, record.id) }
        end
        RakeLogger.log("Migrated batch #{batch_index} (#{records_to_insert.size} records) from #{old_model}.", task)
      else
        RakeLogger.log("Skipping batch #{batch_index}, all records already migrated.", task)
      end
    end

    end_time = Time.now
    time_taken = end_time - start_time
    RakeLogger.log("#{new_model.to_s} data migration completed in #{time_taken} seconds", task)
  end
end
