# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Adapters
    module Providers
      module SharePoint
        module Queries
          module Internal
            class ChildrenQuery < Base
              FIELDS = "?$select=id,name,size,webUrl,lastModifiedBy,createdBy,fileSystemInfo,file,folder,parentReference"

              def self.call(storage:, http:, drive_id:, location:)
                new(storage).call(drive_id:, http:, location:)
              end

              def initialize(storage)
                super
                @transformer = StorageFileTransformer.new(site_name)
              end

              def call(http:, drive_id:, location:)
                handle_response(http.get(request_uri(drive_id, location) + FIELDS)).bind { parse_response(it) }
              end

              private

              def request_uri(drive_id, _location)
                UrlBuilder.url(base_uri, "/v1.0/drives/#{drive_id}/root/children")
              end

              def handle_response(response)
                error = Results::Error.new(source: self.class, payload: response)

                case response
                in { status: 200..299 }
                  Success(response.json(symbolize_keys: true))
                in { status: 400 }
                  Failure(error.with(code: :request_error))
                in { status: 404 }
                  Failure(error.with(code: :not_found))
                in { status: 403 }
                  Failure(error.with(code: :forbidden))
                in { status: 401 }
                  Failure(error.with(code: :unauthorized))
                else
                  Failure(error.with(code: :error))
                end
              end

              def parse_response(json)
                files = json[:value].filter_map { @transformer.transform(it).value_or(nil) }
                parent_reference = json[:value].first[:parentReference]

                Results::StorageFileCollection.build(
                  files:,
                  parent: parent(parent_reference),
                  ancestors: forge_ancestors(parent_reference)
                )
              end

              def parent(parent_reference)
                _, _, name = parent_reference[:path].gsub(/.*root:/, "").rpartition "/"

                if name.empty?
                  drive_root(parent_reference)
                else
                  @transformer.parent_transform(id: parent_reference[:id], name:, location: parent_reference)
                end
              end

              def forge_ancestors(parent_reference)
                path_elements = parent_reference[:path].gsub(/.+root:/, "").split("/")

                path_elements[0..-2].map do |component|
                  next root(Digest::SHA256.hexdigest("i_am_root")) if component.blank?

                  Results::StorageFile.new(
                    id: Digest::SHA256.hexdigest(component),
                    name: component,
                    location: UrlBuilder.path(component)
                  )
                end
              end

              def drive_root(parent_reference)
                name, drive_id = parent_reference.slice(:name, :driveId).values
                Results::StorageFile.new(name:,
                                         location: UrlBuilder.path("/#{site_name}/#{name}"),
                                         id: "#{drive_id}||",
                                         mime_type: "application/x-op-drive",
                                         permissions: %i[readable writeable])
              end

              def root(id)
                Results::StorageFile.new(name: site_name, location: "/", id:, permissions: %i[readable writeable])
              end
            end
          end
        end
      end
    end
  end
end
