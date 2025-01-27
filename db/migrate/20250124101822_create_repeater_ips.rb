class CreateRepeaterIps < ActiveRecord::Migration[7.0]
  def change
    create_table :repeater_ips, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.references :repeater, null: false, foreign_key: true
      t.string :private_ip, null: false
      t.string :public_ip, null: false

      t.timestamps
    end

    add_index :repeater_ips, :private_ip, unique: true
    add_index :repeater_ips, :public_ip, unique: true
  end
end
