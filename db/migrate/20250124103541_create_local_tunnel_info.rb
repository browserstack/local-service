class CreateLocalTunnelInfo < ActiveRecord::Migration[7.0]
  def change
    create_table :local_tunnel_info, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint :user_or_group_id, null: false
      t.string :auth_token, null: false
      t.string :local_identifier, null: false
      t.boolean :force_local, default: false
      t.string :username
      t.integer :rotation_limit
      t.integer :rotation_counter
      t.string :region
      t.string :proxy_type
      t.string :tunnel_type
      t.string :hashed_identifier, limit: 40, null: false
      t.text :backup_repeaters_address

      t.timestamps
    end

    add_index :local_tunnel_info, :auth_token, unique: true, name: "index_local_tunnel_info_on_auth_token"
    add_index :local_tunnel_info, :hashed_identifier, unique: true, name: "index_local_tunnel_info_on_hashed_identifier"
  end
end
