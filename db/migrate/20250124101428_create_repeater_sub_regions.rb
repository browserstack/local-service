class CreateRepeaterSubRegions < ActiveRecord::Migration[7.0]
  def change
    create_table :repeater_sub_regions, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.references :repeater_region, null: false, foreign_key: true
      t.string :dc_name, null: false
      t.float :latitude, null: false
      t.float :longitude, null: false
      t.string :state, null: false, default: "up"

      t.timestamps
    end

    add_index :repeater_sub_regions, :dc_name, unique: true
    add_index :repeater_sub_regions, :state
  end
end
