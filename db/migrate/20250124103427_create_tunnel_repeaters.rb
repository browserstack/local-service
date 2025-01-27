class CreateTunnelRepeaters < ActiveRecord::Migration[7.0]
  def change
    create_table :tunnel_repeaters, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.references :repeater, null: false, foreign_key: true
      t.bigint :tunnel_id, null: false
      t.bigint :user_or_group_id, null: false
      t.string :association_type, null: false

      t.timestamps
    end

    add_index :tunnel_repeaters, [:tunnel_id, :repeater_id], unique: true, name: "index_tunnel_repeaters_on_tunnel_and_repeater"
  end
end
