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
  module Admin
    module Health
      class HealthReportComponent < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include OpTurbo::Streamable

        def initialize(storage:, report:)
          super(storage)
          @report = report
        end

        private

        def data
          @data ||= compute_display_data
        end

        def compute_display_data
          return {} if @report.nil?

          description = if @report.healthy?
                          I18n.t("storages.health.summary.success")
                        elsif @report.unhealthy?
                          I18n.t("storages.health.summary.failure")
                        else
                          I18n.t("storages.health.summary.warning")
                        end

          {
            summary: summary_with_icon(@report.tally),
            description:
          }
        end

        def group_summary(group)
          icon = group.failure? || group.warning? ? :alert : "check-circle"
          icon_color = if group.failure?
                         :danger
                       elsif group.warning?
                         :attention
                       else
                         :success
                       end

          checks = group.tally
          key = group.failure? || group.success? ? :failure : :warning

          { icon:, icon_color:, text: I18n.t("storages.health.checks.#{key.to_s.pluralize}", count: checks[key]) }
        end

        def summary_with_icon(check_tally)
          case check_tally
          in { failure: 1.. }
            {
              icon: :alert,
              icon_color: :danger,
              text: I18n.t("storages.health.checks.failures", count: check_tally[:failure])
            }
          in { warning: 1.. }
            {
              icon: :alert,
              icon_color: :attention,
              text: I18n.t("storages.health.checks.warnings", count: check_tally[:warning])
            }
          else
            { icon: :"check-circle", icon_color: :success, text: I18n.t("storages.health.checks.failures", count: 0) }
          end
        end
      end
    end
  end
end
