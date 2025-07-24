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
            let(:storage) { create(:share_point_storage, oauth_client_token_user: user) }

            let(:auth_strategy) { Registry["share_point.authentication.userless"].call(false) }
            let(:input_data) { Input::Files.build(folder:).value! }

            it_behaves_like "adapter files_query: basic query setup"

            context "when parent folder is root, return a list of drives", vcr: "share_point/files_query_root" do
              let(:folder) { "/" }
              let(:files_result) do
                Results::StorageFileCollection.new(
                  files: [
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Qconfm2i6SKEoCmuGYqQK",
                      name: "OpenProject",
                      mime_type: "application/x-op-drive",
                      location: "/drives/b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Qconfm2i6SKEoCmuGYqQK",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY87vnZ6fgfvQanZHX-XCAyw",
                      name: "Shared Documents",
                      mime_type: "application/x-op-drive",
                      location: "/drives/b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY87vnZ6fgfvQanZHX-XCAyw",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Pmdpc8mQ1QJkyIbbWQJol",
                      name: "Selected Permissions",
                      mime_type: "application/x-op-drive",
                      location: "/drives/b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8Pmdpc8mQ1QJkyIbbWQJol",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY_YoKf1JPvYSJeFRsyx4zF_",
                      name: "Chris document library",
                      mime_type: "application/x-op-drive",
                      location: "/drives/b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY_YoKf1JPvYSJeFRsyx4zF_",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8CfNaHr_0ERYs5kgmEWFrX",
                      name: "Marcello AMPF",
                      mime_type: "application/x-op-drive",
                      location: "/drives/b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8CfNaHr_0ERYs5kgmEWFrX",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8opHtYeMANTahXlS54FgHn",
                      name: "Dominic",
                      mime_type: "application/x-op-drive",
                      location: "/drives/b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY8opHtYeMANTahXlS54FgHn",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY93AQ5rgPKoR7tMwpspgj95",
                      name: "Markus",
                      mime_type: "application/x-op-drive",
                      location: "/drives/b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY93AQ5rgPKoR7tMwpspgj95",
                      permissions: %i[readable writeable]
                    ),
                    Results::StorageFile.new(
                      id: "b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW",
                      name: "Marcello VCR",
                      mime_type: "application/x-op-drive",
                      location: "/drives/b!FeOZEMfQx0eGQKqVBLcP__BG8mq-4-9FuRqOyk3MXY9jo6leJDqrT7muzvmiWjFW",
                      permissions: %i[readable writeable]
                    )
                  ],
                  parent: Results::StorageFile.new(id: "1269877d26360587caf07834bc72ee3ad3c3698f1651bf85d8562e7fda19aa0f",
                                                   name: "OPTest",
                                                   location: "/",
                                                   permissions: %i[readable writeable]),
                  ancestors: []
                )
              end

              it_behaves_like "adapter files_query: successful files response"
            end
          end
        end
      end
    end
  end
end
