class RedisUtils
  def self.store_migration_record(table_name, val)
    DEFAULT_REDIS_CLIENT.sadd("#{table_name}_migrated_rows", val)
  end

  def self.already_migrated?(table_name, old_record)
    DEFAULT_REDIS_CLIENT.sismember("#{table_name}_migrated_rows", val)
  end

  def self.get_migration_table_batch_size(table_name)
    DEFAULT_REDIS_CLIENT.get("#{table_name}_batch_size")
  end

  def self.set_migration_table_batch_size(table_name, batch_size)
    DEFAULT_REDIS_CLIENT.set("#{table_name}_batch_size", batch_size)
  end

  def self.delete_migration_record(table_name, val)
    DEFAULT_REDIS_CLIENT.srem("#{table_name}_migrated_rows", val)
  end

  def self.delete_migration_key(table_name)
    DEFAULT_REDIS_CLIENT.del("#{table_name}_migrated_rows")
  end
end