require 'zip'
require 'datacite/mapping'
require 'stash/wrapper'
require 'tempfile'
require 'stash_ezid/client'
require 'fileutils'
require 'stash_datacite/dublin_core_builder'
require 'stash_datacite/data_one_manifest_builder'

module StashDatacite
  module Resource
    class ResourceFileGeneration
      def initialize(resource, current_tenant)
        @resource = resource
        @current_tenant = current_tenant
        @version = @resource.next_version
        ResourceFileGeneration.set_pub_year(@resource)
        @client = StashEzid::Client.new(@current_tenant.identifier_service.to_h)
      end

      def generate_identifier
        if @resource.identifier
          "#{@resource.identifier.identifier_type.downcase}:#{@resource.identifier.identifier}"
        else
          @client.mint_id
        end
      end

      def generate_xml(target_url, identifier)
        simple_id = identifier.split(':', 2)[1]

        dm = Datacite::Mapping
        st = Stash::Wrapper


        @type = @resource.resource_type.resource_type_mapping_obj

        # # Based on "Example for a simple dataset"
        # # http://schema.datacite.org/meta/kernel-3/example/datacite-example-dataset-v3.0.xml

        resource = dm::Resource.new(
          identifier: dm::Identifier.new(value: simple_id),

          creators: @resource.creators.map do |creator|
            dm::Creator.new(name: "#{creator.creator_full_name}")
          end,

          contributors: @resource.contributors.map do |contributor|
            dm::Contributor.new(name: "#{contributor.contributor_name}", type: dm::ContributorType::FUNDER)
          end,

          titles: [
              dm::Title.new(value: "#{@resource.titles.where(title_type: nil).first.title}")
          ],

          publisher: "#{@resource.publisher.publisher || 'unknown'}",

          publication_year: Time.now.year,

          subjects: @resource.subjects.map do |subject|
            dm::Subject.new(value: "#{subject.subject}")
          end,

          language: 'en',

          resource_type: dm::ResourceType.new(resource_type_general: @type, value: nil ),

          version: @version,

          descriptions: [
            dm::Description.new(
                type: dm::DescriptionType::ABSTRACT,
                value: "#{@resource.descriptions.where(description_type: :abstract).first.description}"
            ),
            dm::Description.new(
                type: dm::DescriptionType::METHODS,
                value: "#{@resource.descriptions.where(description_type: :methods).first.description}"
            ),
            dm::Description.new(
                type: dm::DescriptionType::OTHER,
                value: "#{@resource.descriptions.where(description_type: :other).first.description}"
            )
          ],

          geo_locations:
              @resource.geolocations.map do |geo|
                dm::GeoLocation.new(
                  place: geo.datacite_mapping_place,
                  point: geo.datacite_mapping_point,
                  box: geo.datacite_mapping_box)
              end
        )

        datacite_to_wrapper = resource.save_to_xml
        datacite_root = resource.write_xml
        @client.update_metadata(identifier, datacite_root, target_url) # add target as 3rd parameter

        # datacite_target = "#{@resource.id}_datacite.xml"
        # datacite_directory = "#{Rails.root}/uploads"
        # puts Dir.pwd
        #f = File.open("#{datacite_directory}/#{datacite_target}", 'w') { |f| f.write(datacite_root) }

        identifier = st::Identifier.new(
          type: st::IdentifierType::DOI,
          value: '10.14749/1407399498'
        )

        version = st::Version.new(
          number: @version,
          date:  Date.tomorrow,
          note: 'Sample wrapped Datacite document'
        )

        r = @resource.rights.try(:first)
        license = st::License.new(name: r.rights , uri: r.rights_uri) if r

        embargo = st::Embargo.new(
          type: st::EmbargoType::NONE,
          period: 'none',
          start_date: Date.tomorrow,
          end_date: Date.tomorrow,
        )

        uploads = uploads_list(@resource)
        files = uploads.map do |d|
          st::StashFile.new(
            pathname: "#{d[:name]}", size_bytes: d[:size], mime_type: "#{d[:type]}"
          )
        end
        inventory = st::Inventory.new(files: files)

        wrapper = st::StashWrapper.new(
          identifier: identifier,
          version: version,
          license: license,
          embargo: embargo,
          inventory: inventory,
          descriptive_elements: [datacite_to_wrapper]
        )

        stash_wrapper = wrapper.write_xml
        # stash_wrapper_target = "#{@resource.id}_stash_wrapper.xml"
        # stash_wrapper_directory = "#{Rails.root}/uploads"
        # puts Dir.pwd
        # f = File.open("#{stash_wrapper_directory}/#{stash_wrapper_target}", 'w') { |f| f.write(stash_wrapper) }
        return [datacite_root, stash_wrapper]
      end

      def generate_dublincore
        DublinCoreBuilder.new(resource: @resource, tenant: @current_tenant).build_xml_string
      end

      def generate_dataone
        DataONEManifestBuilder.new(uploads_list(@resource)).build_dataone_manifest
      end

      def generate_merritt_zip(folder, target_url, identifier)
        target_url = target_url
        FileUtils::mkdir_p(folder)

        uploads = @resource.file_uploads.newly_created.map{|i|
                { name: i.upload_file_name, type: i.upload_content_type, size: i.upload_file_size } }
        purge_existing_files

        zipfile_name = "#{folder}/#{@resource.id}_archive.zip"
        datacite_xml, stashwrapper_xml = generate_xml(target_url, identifier)

        File.open("#{folder}/#{@resource.id}_mrt-datacite.xml", "w") do |f|
          f.write datacite_xml
        end
        File.open("#{folder}/#{@resource.id}_stash-wrapper.xml", "w") do |f|
          f.write stashwrapper_xml
        end
        File.open("#{folder}/#{@resource.id}_mrt-oaidc.xml", "w") do |f|
          f.write(generate_dublincore)
        end
        File.open("#{folder}/#{@resource.id}_mrt-dataone-manifest.txt", 'w') do |f|
          f.write(generate_dataone)
        end
        del_fn = create_delete_file(folder)

        Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
          zipfile.add("mrt-datacite.xml", "#{folder}/#{@resource.id}_mrt-datacite.xml")
          zipfile.add("stash-wrapper.xml", "#{folder}/#{@resource.id}_stash-wrapper.xml")
          zipfile.add("mrt-oaidc.xml", "#{folder}/#{@resource.id}_mrt-oaidc.xml")
          zipfile.add("mrt-dataone-manifest.txt", "#{folder}/#{@resource.id}_mrt-dataone-manifest.txt")
          zipfile.add("mrt-delete.txt", del_fn) unless del_fn.nil?
          uploads.each do |d|
            zipfile.add("#{d[:name]}", "#{folder}/#{@resource.id}/#{d[:name]}")
          end
        end

        zipfile_name
      end

      def purge_existing_files
        folder = "#{Rails.root}/uploads/"
        if File.exist?("#{folder}/#{@resource.id}_archive.zip")
          File.delete("#{folder}/#{@resource.id}_archive.zip")
        end
        if File.exist?("#{folder}/#{@resource.id}_mrt-datacite.xml")
          File.delete("#{folder}/#{@resource.id}_mrt-datacite.xml")
        end
        if File.exist?("#{folder}/#{@resource.id}_stash-wrapper.xml")
          File.delete("#{folder}/#{@resource.id}_stash-wrapper.xml")
        end
        if File.exist?("#{folder}/#{@resource.id}_mrt-oaidc.xml")
          File.delete("#{folder}/#{@resource.id}_mrt-oaidc.xml")
        end
        if File.exist?("#{folder}/#{@resource.id}_mrt-dataone-manifest.txt")
          File.delete("#{folder}/#{@resource.id}_mrt-dataone-manifest.txt")
        end
        if File.exist?("#{folder}/#{@resource.id}_mrt-delete.txt")
          File.delete("#{folder}/#{@resource.id}_mrt-delete.txt")
        end
      end

      def uploads_list(resource)
        files = []
        current_uploads = resource.current_file_uploads
        current_uploads.each do |u|
          hash = { name: u.upload_file_name, type: u.upload_content_type, size: u.upload_file_size }
          files.push(hash)
        end
        files
      end

      # create list of files to delete and return filename, return nil if no deletes needed
      def create_delete_file(folder)
        del_files = @resource.file_uploads.deleted
        return nil if del_files.blank?
        fn = "#{folder}/#{@resource.id}_mrt-delete.txt"
        File.open(fn, "w") do |f|
          f.write del_files.map(&:upload_file_name).join("\n")
        end
        fn
      end

      # set the publication year to the current one if it has not been set yet
      def self.set_pub_year(resource)
        return if resource.publication_years.count > 0
        PublicationYear.create({publication_year: Time.now.year, resource_id: resource.id})
      end

    end
  end
end
