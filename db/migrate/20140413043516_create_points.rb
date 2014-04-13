class CreatePoints < ActiveRecord::Migration
  def change
    create_table :points do |t|
      t.integer :dataset_id
      t.integer :year
      t.float :latitude
      t.float :longitude
      t.string :value_name
      t.float :value

      t.timestamps
    end
  end
end
