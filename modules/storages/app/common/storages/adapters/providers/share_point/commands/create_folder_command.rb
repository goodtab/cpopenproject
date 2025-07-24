# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Storages
  module Adapters
    module Providers
      module SharePoint
        module Commands
          class CreateFolderCommand < Base
            # @param auth_strategy [Result(Input::Strategy)]
            # @param input_data [Input::CreateFolder]
            def call(auth_strategy:, input_data:)
              Authentication[auth_strategy].call(storage: @storage) do |_http|
                # Input data has: folder name, parent_location
                # Parent Location here need to be eiter a Drive
                #   Or a pair of Drive + Parent Folder
                Rails.logger.debug request_uri(**drive_and_location(input_data.parent_location))
              end
            end

            private

            def request_uri(drive_id:, location:)
              last_fragment = if location.root?
                                ["/root/children"]
                              else
                                ["/items", parent_location.path, "/children"]
                              end

              UrlBuilder.url(base_uri, "/drives/", drive_id, *last_fragment)
            end
          end
        end
      end
    end
  end
end
