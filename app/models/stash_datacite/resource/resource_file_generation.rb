require 'datacite/mapping'
require 'stash/wrapper'
require 'tempfile'
module StashDatacite
  module Resource
    class ResourceFileGeneration
      def initialize(resource, current_tenant)
        @resource = resource
        @current_tenant = current_tenant
      end

      def generate_xml
        dm = Datacite::Mapping
        st = Stash::Wrapper

        case @resource.resource_type.resource_type
          when "Spreadsheet"
            @type = dm::ResourceTypeGeneral::DATASET
          when "MultipleTypes"
            @type = dm::ResourceTypeGeneral::COLLECTION
          when "Image"
            @type = dm::ResourceTypeGeneral::IMAGE
          when "Sound"
            @type = dm::ResourceTypeGeneral::SOUND
          when "Video"
            @type = dm::ResourceTypeGeneral::AUDIOVISUAL
          when "Text"
            @type = dm::ResourceTypeGeneral::TEXT
          when "Software"
            @type = dm::ResourceTypeGeneral::SOFTWARE
          else
            @type = dm::ResourceTypeGeneral::OTHER
        end
        # # Based on "Example for a simple dataset"
        # # http://schema.datacite.org/meta/kernel-3/example/datacite-example-dataset-v3.0.xml

        resource = dm::Resource.new(
          identifier: dm::Identifier.new(value: '10.5072/D3P26Q35R-Test'),

          creators: @resource.creators.map do |creator|
            dm::Creator.new(name: "#{creator.creator_full_name}")
          end,

          contributors: @resource.contributors.map do |contributor|
            dm::Contributor.new(name: "#{contributor.contributor_name}", type: "#{contributor.contributor_type}")
          end,

          titles: [
              dm::Title.new(value: "#{@resource.titles.where(title_type: :main).first.title}")
          ],

          publisher: "#{@current_tenant.long_name || 'unknown'}",

          publication_year: Time.now.year,

          subjects: @resource.subjects.map do |subject|
            dm::Subject.new(value: "#{subject.subject}")
          end,

          language: 'en',

          resource_type: dm::ResourceType.new(resource_type_general: @type, value: "#{@resource.resource_type.resource_type}" ),

          version: '1',

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
                value: "#{@resource.descriptions.where(description_type: :usage_notes).first.description}"
            )
          ]
        )
        datacite_to_wrapper = resource.save_to_xml
        datacite_root = resource.write_xml
        datacite_target = "#{@resource.id}_datacite.xml"
        datacite_directory = "#{Rails.root}/public/uploads"
        puts Dir.pwd
        f = File.open("#{datacite_directory}/#{datacite_target}", 'w') { |f| f.write(datacite_root) }
        puts datacite_root


        identifier = st::Identifier.new(
          type: st::IdentifierType::DOI,
          value: '10.14749/1407399498'
        )

        version = st::Version.new(
          number: 1,
          date: Date.new(2013, 8, 18),
          note: 'Sample wrapped Datacite document'
        )

        license = st::License::CC_BY

        embargo = st::Embargo.new(
          type: st::EmbargoType::NONE,
          period: 'none',
          start_date: Date.today,
          end_date: Date.today
        )

        inventory = st::Inventory.new(
          files: [
            st::StashFile.new(
              pathname: 'HSRC_MasterSampleII.dat', size_bytes: 12_345, mime_type: 'text/plain'
            ),
            st::StashFile.new(
              pathname: 'HSRC_MasterSampleII.csv', size_bytes: 67_890, mime_type: 'text/csv'
            ),
            st::StashFile.new(
              pathname: 'HSRC_MasterSampleII.sas7bdat', size_bytes: 123_456, mime_type: 'application/x-sas-data'
            ),
          ])

        wrapper = st::StashWrapper.new(
          identifier: identifier,
          version: version,
          license: license,
          embargo: embargo,
          inventory: inventory,
          descriptive_elements: [datacite_to_wrapper]
        )

        stash_wrapper = wrapper.write_xml
        stash_wrapper_target = "#{@resource.id}_stash_wrapper.xml"
        stash_wrapper_directory = "#{Rails.root}/public/uploads"
        puts Dir.pwd
        f = File.open("#{stash_wrapper_directory}/#{stash_wrapper_target}", 'w') { |f| f.write(stash_wrapper) }
        puts stash_wrapper
      end

      def generate_dublincore
        xml_content = File.new("#{Rails.root}/public/uploads/#{@resource.id}_dublincore.xml", "w:ASCII-8BIT")

        dc_builder = Nokogiri::XML::Builder.new do |xml|
          xml.qualifieddc('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                          'xsi:noNamespaceSchemaLocation' => 'http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd',
                          'xmlns:dc' => 'http://purl.org/dc/elements/1.1/',
                          'xmlns:dcterms' => 'http://purl.org/dc/terms/') {

            @resource.creators.each do |c|
              xml.send(:'dc:creator', "#{c.creator_full_name.gsub(/\r/,"")}")
            end

            @resource.contributors.each do |c|
              xml.send(:'dc:contributor', "#{c.contributor_name.gsub(/\r/,"")}")
              xml.send(:'dc:description', "#{c.award_number.gsub(/\r/,"")}")
            end

            xml.send(:'dc:title', "#{@resource.titles.where(title_type: :main).first.title}")
            xml.send(:'dc:publisher', "#{@current_tenant.long_name || 'unknown'}")
            xml.send(:'dc:date', Time.now.year)

            @resource.subjects.each do |s|
              xml.send(:'dc:subject', "#{s.subject.gsub(/\r/,"")}")
            end

            xml.send(:'dc:type', "#{@resource.resource_type.resource_type}")
            #xml.send(:'dcterms:extent', @total_size)

            @resource.rights.each do |r|
              xml.send(:'dc:rights', "#{r.rights}")
              xml.send(:'dcterms:license', "#{r.rights_uri}", "xsi:type" => "dcterms:URI")
            end

            unless @resource.descriptions.blank?
              @resource.descriptions.each do |d|
                xml.send(:'dc:description', "#{d.description.gsub(/\r/,"")}")
              end
            end

            @relation_types = StashDatacite::RelationType.all
            @resource.related_identifiers.each do |r|

              case r.relation_type
                when "IsPartOf"
                  xml.send(:'dcterms:isPartOf', "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "HasPart"
                  xml.send(:'dcterms:hasPart',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsCitedBy"
                  xml.send(:'dcterms:isReferencedBy',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "Cites"
                  xml.send(:'dcterms:references',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsReferencedBy"
                  xml.send(:'dcterms:isReferencedBy',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "References"
                  xml.send(:'dcterms:references',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsNewVersionOf"
                  xml.send(:'dcterms:isVersionOf',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsPreviousVersionOf"
                  xml.send(:'dcterms:hasVersion',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsVariantFormOf"
                  xml.send(:'dcterms:isVersionOf',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                when "IsOriginalFormOf"
                  xml.send(:'dcterms:hasVersion',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
                else
                  xml.send(:'dcterms:relation',  "#{r.related_identifier_type.related_identifier_type}" + ": " + "#{r.related_identifier}")
              end
            end

          }
        end

        f = File.open("#{Rails.root}/public/uploads/#{@resource.id}_dublincore.xml", 'w') { |f| f.print(dc_builder.to_xml) }
        puts dc_builder.to_xml.to_s
        dc_builder.to_xml.to_s
      end

      def generate_dataone
        File.new("#{Rails.root}/public/uploads/#{@resource.id}_dataone.txt", "w:ASCII-8BIT")

        @files = uploads_list(@resource)
        content =   "#%dataonem_0.1 " + "\n" +
            "#%profile | http://uc3.cdlib.org/registry/ingest/manifest/mrt-dataone-manifest " + "\n" +
            "#%prefix | dom: | http://uc3.cdlib.org/ontology/dataonem " + "\n" +
            "#%prefix | mrt: | http://uc3.cdlib.org/ontology/mom " + "\n" +
            "#%fields | dom:scienceMetadataFile | dom:scienceMetadataFormat | " +
            "dom:scienceDataFile | mrt:mimeType " + "\n"

        @files.each do |file|
          if file
            content <<    "mrt-datacite.xml | http://schema.datacite.org/meta/kernel-3/metadata.xsd | " +
                "#{file[:name]}" + " | #{file[:type]} " + "\n" + "mrt-dc.xml | " +
                "http://dublincore.org/schemas/xmls/qdc/2008/02/11/qualifieddc.xsd | " +
                "#{file[:name]}" + " | #{file[:type]} " + "\n"
          end
        end
        content << "#%eof "

        File.open("#{Rails.root}/public/uploads/#{@resource.id}_dataone.txt", 'w') do |f|
          f.write(content)
        end
        puts content.to_s
        content.to_s
      end

      def uploads_list(resource)
        files = []
        current_uploads = resource.file_uploads
        current_uploads.each do |u|
          hash = {:name => u.upload_file_name, :type => u.upload_content_type}
          files.push(hash)
        end
        files
      end

    end
  end
end
