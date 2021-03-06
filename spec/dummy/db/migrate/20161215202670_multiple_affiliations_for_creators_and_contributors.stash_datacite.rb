# This migration comes from stash_datacite (originally 20160720210159)
class MultipleAffiliationsForCreatorsAndContributors < ActiveRecord::Migration
  def change
    create_table :dcs_affiliations_dcs_creators do |t|
      t.integer :affiliation_id
      t.integer :creator_id
      t.timestamps null: false
    end

    create_table :dcs_affiliations_dcs_contributors do |t|
      t.integer :affiliation_id
      t.integer :contributor_id
      t.timestamps null: false
    end
  end
end
