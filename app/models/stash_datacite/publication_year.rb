module StashDatacite
  class PublicationYear < ActiveRecord::Base
    self.table_name = 'dcs_publication_years'
    belongs_to :resource, class_name: StashDatacite.resource_class.to_s

    def self.ensure_pub_year(resource)
      return if resource.publication_years.exists?
      create(publication_year: Time.now.year, resource_id: resource.id)
    end
  end
end
