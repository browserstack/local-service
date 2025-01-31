class CreateRepeaters < ActiveRecord::Migration[7.0]
  def change
    create_table :repeaters, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.string :host_name, null: false
      t.references :repeater_region, null: false, foreign_key: true
      t.references :repeater_sub_region, null: false, foreign_key: true
      t.string :state, null: false, default: "active"
      t.string :repeater_type, null: false

      t.timestamps
    end

    add_index :repeaters, :host_name, unique: true
    add_index :repeaters, :state
  end
end
