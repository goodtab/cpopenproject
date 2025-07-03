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

class AllMeetingsICalService
  include Meetings::ICalHelpers
  attr_reader :user, :url_helpers, :include_historic, :calendar, :timezone

  def initialize(user:, include_historic: false)
    @user = user
    @timezone = user.time_zone
    @url_helpers = OpenProject::StaticRouting::StaticUrlHelpers.new
    @include_historic = include_historic
    @calendar = build_icalendar(Time.current.in_time_zone(user.time_zone))
  end

  def call
    single_meetings.each do |meeting|
      build_single_meeting(meeting)
    end

    ServiceResult.success(result: calendar.to_ical)
  end

  private

  def build_single_meeting(meeting) # rubocop:disable Metrics/AbcSize
    tzinfo = timezone.tzinfo
    tzid = tzinfo.canonical_identifier

    calendar.event do |e|
      e.dtstart = ical_datetime meeting.start_time, tzid
      e.dtend = ical_datetime meeting.end_time, tzid
      e.url = url_helpers.meeting_url(meeting)
      e.summary = "[#{meeting.project.name}] #{meeting.title}"
      e.description = ical_subject(meeting)
      e.uid = "#{meeting.id}@#{meeting.project.identifier}"
      e.organizer = ical_organizer
      e.location = meeting.location.presence

      # set_status(cancelled, e)
      add_attendees(e, meeting)
    end
  end

  def ical_subject(meeting)
    "[#{meeting.project.name}] #{I18n.t(:label_meeting)}: #{meeting.title}"
  end

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
