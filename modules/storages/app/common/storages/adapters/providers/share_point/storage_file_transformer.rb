# frozen_string_literal: true

#-- copyright
#++

module Storages
  module Adapters
    module Providers
      module SharePoint
        class StorageFileTransformer < OneDrive::StorageFileTransformer
          attr_reader :site_name

          def initialize(site_name)
            @site_name = site_name
          end

          private

          def extract_location(parent_reference, file_name)
            appendix = file_name.blank? ? "" : "/#{file_name}"

            "/#{site_name}/#{parent_reference[:name]}#{appendix}"
          end

          def id(json)
            "#{json.dig(:parentReference, :driveId)}#{SharePointStorage::IDENTIFIER_SEPARATOR}#{json[:id]}"
          end
        end
      end
    end
  end
end
