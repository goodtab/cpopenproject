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
        module Queries
          module Internal
            class ListsQuery < Base
              FIELDS = "?$expand=drive&$select=id,name,drive"

              def self.call(storage:, http:)
                new(storage).call(http)
              end

              def call(http)
                handle_response(http.get(request_uri + FIELDS)).fmap { parse_response(it) }
              end

              private

              def handle_response(response)
                error = Results::Error.new(source: self, payload: response)

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
                json[:value].filter_map do |entry|
                  Results::StorageFile.build(
                    name: entry[:name],
                    id: entry.dig(:drive, :id),
                    mime_type: "application/x-op-drive",
                    location: "/drives/#{entry.dig(:drive, :id)}",
                    permissions: %i[readable writeable]
                  ).value_or { nil }
                end
              end

              def request_uri
                storage_host = URI(@storage.host)
                URI.join(base_uri.origin, "/v1.0/sites/#{storage_host.host}:#{storage_host.path}:/lists").to_s
              end
            end
          end
        end
      end
    end
  end
end
