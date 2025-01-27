class CreateLocalHubRepeaterRegions < ActiveRecord::Migration[7.0]
  def change
    create_table :local_hub_repeater_regions, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.bigint :user_or_group_id, null: false
      t.string :association_type, null: false
      t.string :hub_repeater_sessions
      t.timestamps default: -> { 'CURRENT_TIMESTAMP' }, null: false
    end

    add_index :local_hub_repeater_regions, [:user_or_group_id, :association_type], unique: true, name: "index_local_hub_repeater_regions_on_user_or_group_and_type"
  end
end
