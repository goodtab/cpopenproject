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

require "spec_helper"
require_module_spec_helper

module Storages
  module Adapters
    module Providers
      module SharePoint
        module Queries
          RSpec.describe FilesQuery, :webmock do
            let(:user) { create(:admin) }
            let(:storage) { create(:share_point_dev_storage, oauth_client_token_user: user) }

            let(:auth_strategy) { Registry["share_point.authentication.userless"].call(false) }
            let(:input_data) { Input::Files.build(folder:).value! }

            it_behaves_like "adapter files_query: basic query setup"

            # rubocop:disable Layout/LineLength
            context "when parent folder is root, return a list of drives", vcr: "share_point/files_query_root" do
              let(:folder) { "/" }
              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Qconfm2i6SKEoCmuGYqQK||",
                      name: "OpenProject",
                      mime_type: "application/x-op-drive",
                      location: "/OPTest/OpenProject",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY87vnZ6fgfvQanZHX-XCAyw||",
                      name: "Shared Documents",
                      mime_type: "application/x-op-drive",
                      location: "/OPTest/Shared%20Documents",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Pmdpc8mQ1QJkyIbbWQJol||",
                      name: "Selected Permissions",
                      mime_type: "application/x-op-drive",
                      location: "/OPTest/Selected%20Permissions",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY_YoKf1JPvYSJeFRsyx4zF_||",
                      name: "Chris document library",
                      mime_type: "application/x-op-drive",
                      location: "/OPTest/Chris%20document%20library",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8CfNaHr_0ERYs5kgmEWFrX||",
                      name: "Marcello AMPF",
                      mime_type: "application/x-op-drive",
                      location: "/OPTest/Marcello%20AMPF",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8opHtYeMANTahXlS54FgHn||",
                      name: "Dominic",
                      mime_type: "application/x-op-drive",
                      location: "/OPTest/Dominic",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY93AQ5rgPKoR7tMwpspgj95||",
                      name: "Markus",
                      mime_type: "application/x-op-drive",
                      location: "/OPTest/Markus",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||",
                      name: "Marcello VCR",
                      mime_type: "application/x-op-drive",
                      location: "/OPTest/Marcello%20VCR",
                      permissions: %i[readable writeable]
                    )
                  ],
                  parent: Results::StorageFile.new(id: "1269877d26360587caf07834bc72ee3ad3c3698f1651bf85d8562e7fda19aa0f",
                                                   name: "OPTest",
                                                   location: "/OPTest",
                                                   permissions: %i[readable writeable]),
                  ancestors: []
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end

            context "when requesting a drive, return the list of all folders", vcr: "share_point/files_query_drive" do
              let(:folder) { "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||" }
              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53W5P3SUY3ZCDTRA3KLXRGA5A2M3S",
                      name: "data",
                      size: 0,
                      mime_type: "application/x-op-directory",
                      created_at: Time.zone.parse("2025-04-07 12:02:26Z"),
                      last_modified_at: Time.zone.parse("2025-04-07 12:02:26Z"),
                      created_by_name: "Eric Schubert",
                      last_modified_by_name: "Eric Schubert",
                      location: "/OPTest/Marcello%20VCR/data",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||01ANJ53WZVLAWJSVFKOFF3HLYZPMPUK6HI",
                      name: "simply_oidc.jpg",
                      size: 56483,
                      mime_type: "image/jpeg",
                      created_at: Time.zone.parse("2025-04-07 12:02:42Z"),
                      last_modified_at: Time.zone.parse("2025-04-07 12:02:42Z"),
                      created_by_name: "Eric Schubert",
                      last_modified_by_name: "Eric Schubert",
                      location: "/OPTest/Marcello%20VCR/simply_oidc.jpg",
                      permissions: %i[readable writeable]
                    )
                  ],
                  parent: Results::StorageFile.new(
                    id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW||",
                    name: "Marcello VCR",
                    mime_type: "application/x-op-drive",
                    location: "/OPTest/Marcello%20VCR",
                    permissions: %i[readable writeable]
                  ),
                  ancestors: []
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end
            # rubocop:enable Layout/LineLength
          end
        end
      end
    end
  end
end
