class CreateLocalTunnelInfoLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :local_tunnel_info_logs, id: :integer, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci" do |t|
      t.string :hashed_id, null: false
      t.bigint :user_or_group_id, null: false
      t.string :association_type, null: false
      t.string :auth_token, null: false
      t.text :system_details
      t.text :local_identifier
      t.integer :local_tunnel_info_id, null: false 
      t.text :data
      t.text :params
      t.integer :json_version, null: false
      t.boolean :display, default: false
      t.text :misc_data

      t.timestamps
    end

    add_index :local_tunnel_info_logs, :hashed_id, unique: true
    add_index :local_tunnel_info_logs, :local_tunnel_info_id, unique: true
    add_index :local_tunnel_info_logs, [:user_or_group_id, :association_type], name: "index_local_tunnel_info_logs_on_user_or_group_and_type"
    add_index :local_tunnel_info_logs, :auth_token
  end
end
