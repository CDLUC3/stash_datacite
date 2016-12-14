# This migration comes from stash_datacite (originally 20151116143020)
class CreateDcsGeoLocationPlace < ActiveRecord::Migration
  def change
    create_table :dcs_geo_location_places do |t|
      t.string :geo_location_place
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end
