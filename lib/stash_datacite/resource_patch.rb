#for monkeypatching shared resource to have associations
module StashDatacite
  module ResourcePatch
    #has_many :titles, class_name: 'StashDatacite::Title'

    # This patches the resource class to have associations and convenience methods.
    # I'm putting them here since the resource may be used by different metadata
    # engines.  It makes sense for the engine to know a little something about the main
    # application since it will remain constant while an engine may change.
    #
    # The designers of a new metadata engine will need to do some set-up to design it
    # to work with Stash, but a user should not have to configure associations for
    # an engine.
    #
    # We could add methods to a class more directly if we were not defining the shared resource
    # class in the configuration.  As it is, it's problematic to change the class until being
    # certain that the configuration is loaded and so the resource class is defined.  We could
    # probably make it straight forward if we didn't allow the shared resource class to be user-configurable.
    def self.associate_with_resource(resource)
      resource.instance_eval do
        has_many :contributors, class_name: 'StashDatacite::Contributor' # optional according to datacite
        has_many :creators, class_name: 'StashDatacite::Creator' # mandatory
        has_many :dates, class_name: 'StashDatacite::Date' # optional
        has_many :descriptions, class_name: 'StashDatacite::Description' #optional
        has_many :embargoes, class_name: 'StashDatacite::Embargo' #?
        has_many :geolocation_boxes, class_name: 'StashDatacite::GeolocationBox' # optional
        has_many :geolocation_places, class_name: 'StashDatacite::GeolocationPlace' # optional
        has_many :geolocation_points, class_name: 'StashDatacite::GeolocationPoint' # optional
        has_many :publication_years, class_name: 'StashDatacite::PublicationYear' # required
        has_many :publishers, class_name: 'StashDatacite::Publisher' # required
        has_many :related_identifiers, class_name: 'StashDatacite::RelatedIdentifier' # optional
        has_one :resource_type, class_name: 'StashDatacite::ResourceType' # optional
        has_many :rights, class_name: 'StashDatacite::Right' # optional
        has_one :size, class_name: 'StashDatacite::Size' # optional
        has_and_belongs_to_many :subjects, class_name: 'StashDatacite::Subject', through: 'StashDatacite::ResourceSubject' #optional
        has_many :titles, class_name: 'StashDatacite::Title' # required
        has_one :version, class_name: 'StashDatacite::Version' # optional

      end
    end
  end
end