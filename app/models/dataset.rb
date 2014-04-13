class Dataset < ActiveRecord::Base
  has_many :points

  default_scope { order(:name) }
end
