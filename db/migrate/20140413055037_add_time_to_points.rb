class AddTimeToPoints < ActiveRecord::Migration
  def change
    add_column :points, :time, :datetime
  end
end
