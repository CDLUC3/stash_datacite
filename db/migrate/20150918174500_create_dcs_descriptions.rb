class CreateDcsDescriptions < ActiveRecord::Migration
  def change
    create_table :dcs_descriptions do |t|
      t.text  :description
      t.column :description_type, :integer, default: 0
      t.integer :resource_id

      t.timestamps null: false
    end
  end
end