class CreateDatasets < ActiveRecord::Migration
  def change
    create_table :datasets do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
  end
end
