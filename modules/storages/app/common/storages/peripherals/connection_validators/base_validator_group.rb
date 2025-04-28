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
      class BaseValidatorGroup
        include TaggedLogging

        def self.call(storage)
          new(storage).call
        end

        def initialize(storage)
          @storage = storage
          @results = ValidationGroupResult.new
        end

        def call
          catch :interrupted do
            validate
          end

          @results
        end

        private

        def validate = raise Errors::SubclassResponsibility

        def register_checks(*keys)
          keys.each { @results.register_check(it) }
        end

        def update_result(...)
          @results.update_result(...)
        end

        def pass_check(key)
          update_result(key, CheckResult.success(key))
        end

        def fail_check(key, message)
          update_result(key, CheckResult.failure(key, message))
          throw :interrupted
        end

        def warn_check(key, message, halt_validation: false)
          update_result(key, CheckResult.warning(key, message))
          throw :interrupted if halt_validation
        end

        def message(key, context = {})
          I18n.t("storages.health.connection_validation.#{key}", **context)
        end
      end
    end
  end
end
