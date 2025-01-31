class CreateDedicatedRepeaterAllocations < ActiveRecord::Migration[7.0]
  def change
    create_table :dedicated_repeater_allocations, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.references :repeater, null: false, foreign_key: true
      t.references :repeater_ip, null: false, foreign_key: true
      t.bigint :user_or_group_id, null: false
      t.string :association_type, null: false

      t.timestamps
    end

    add_index :dedicated_repeater_allocations, [:user_or_group_id, :repeater_id], unique: true, name: "index_dedicated_repeater_allocations"
  end
end
