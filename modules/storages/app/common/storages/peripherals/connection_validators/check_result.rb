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
  module Peripherals
    module ConnectionValidators
      CheckResult = Data.define(:key, :state, :message, :timestamp) do
        private_class_method :new
        def self.skipped(key)
          new(key:, state: :skipped, message: nil, timestamp: nil)
        end

        def self.failure(key, message)
          new(key:, state: :failure, message:, timestamp: Time.zone.now)
        end

        def self.success(key)
          new(key:, state: :success, message: nil, timestamp: Time.zone.now)
        end

        def self.warning(key, message)
          new(key:, state: :warning, message:, timestamp: Time.zone.now)
        end

        def success? = state == :success
        def failure? = state == :failure
        def warning? = state == :warning
        def skipped? = state == :skipped

        def to_h
          { state: state.to_s, message:, timestamp: timestamp&.iso8601 }
        end
      end
    end
  end
end
