# This migration comes from stash_datacite (originally 20160714213354)
class AddOtherToDescriptionEnum < ActiveRecord::Migration
  def change
    change_table :dcs_descriptions do |t|
      t.change :description_type, "ENUM('abstract', 'methods', 'seriesinformation', 'tableofcontents', 'other', 'usage_notes') DEFAULT NULL"
    end
  end
end
