# This migration comes from stash_datacite (originally 20150917193254)
class CreateDcsTitles < ActiveRecord::Migration
  def change
    create_table :dcs_titles do |t|
      t.string :title
      t.column :title_type, "ENUM('main', 'alternative_title', 'subtitle', 'translated_title') DEFAULT 'main'"
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end