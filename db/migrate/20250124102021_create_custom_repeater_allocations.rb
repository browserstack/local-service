class CreateCustomRepeaterAllocations < ActiveRecord::Migration[7.0]
  def change
    create_table :custom_repeater_allocations, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.references :repeater, null: false, foreign_key: true
      t.bigint :user_or_group_id, null: false
      t.string :association_type, null: false
      t.string :allocation_type, null: false

      t.timestamps
    end

    add_index :custom_repeater_allocations, [:user_or_group_id, :repeater_id], unique: true, name: "index_custom_repeater_allocations_on_user_or_group_and_repeater"
  end
end
