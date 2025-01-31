class CreateRepeaterRegions < ActiveRecord::Migration[7.0]
  def change
    create_table :repeater_regions do |t|
      t.string :dc_name, null: false
  
      t.timestamps
    end
  
    add_index :repeater_regions, :dc_name, unique: true
  end
end
