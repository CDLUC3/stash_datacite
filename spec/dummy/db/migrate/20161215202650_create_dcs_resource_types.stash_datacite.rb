# This migration comes from stash_datacite (originally 20151107180429)
class CreateDcsResourceTypes < ActiveRecord::Migration
  def change
    create_table :dcs_resource_types do |t|
      t.column :resource_type, "ENUM('dataset', 'image', 'sound', 'audiovisual',
                                     'text', 'software', 'collection', 'other',
                                     'event', 'interactive_resource',
                                     'model', 'physical_object', 'service', 'workflow') DEFAULT NULL"
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end

