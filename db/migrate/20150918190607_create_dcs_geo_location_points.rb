class CreateDcsGeoLocationPoints < ActiveRecord::Migration
  def change
    create_table :dcs_geo_location_points do |t|
      t.float :latitude
      t.float :longitude
      t.text :geo_location_place
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end