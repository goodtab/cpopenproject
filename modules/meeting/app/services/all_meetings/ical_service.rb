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
require "icalendar"
require "icalendar/tzinfo"
module AllMeetings
  class ICalService
    attr_reader :user, :include_historic

    def initialize(user:, include_historic: false)
      @user = user
      @include_historic = include_historic
    end

    def call # rubocop:disable Metrics/AbcSize
      User.execute_as(user) do
        calendar = Meetings::CalendarWrapper.new(timezone: Time.zone || Time.zone_default)

        single_meetings.each do |meeting|
          calendar.add_single_meeting_event(meeting:, cancelled: false)
        end

        # This generates a lot of subqueries.
        # TODO: Optimize this to avoid subqueries.
        recurring_meetings.each do |recurring_meeting|
          calendar.add_series_event(recurring_meeting:, cancelled: false)
        end

        ServiceResult.success(result: calendar.to_ical)
      end
    rescue StandardError => e
      Rails.logger.error("Failed to generate ICS for meeting #{@meeting.id}: #{e.message}")
      ServiceResult.failure(message: e.message)
    end

    private

    def recurring_meetings
      @recurring_meetings ||= RecurringMeeting.visible(user)
    end

    def single_meetings
      @single_meetings ||= if include_historic
                             Meeting.not_recurring.visible(user)
                           else
                             Meeting.not_recurring.from_today.visible(user)
                           end
    end
  end
end
