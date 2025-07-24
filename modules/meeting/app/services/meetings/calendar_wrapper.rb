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

module Meetings
  class CalendarWrapper
    attr_reader :timezone, :calendar, :calendar_timezones

    def initialize(timezone:)
      @timezone = timezone
      @calendar = build_icalendar
      @calendar_timezones = Set.new
    end

    def add_single_meeting_event(meeting:, cancelled: false) # rubocop:disable Metrics/AbcSize
      calendar.event do |e|
        e.dtstart = ical_datetime(meeting.start_time)
        e.dtend = ical_datetime(meeting.end_time)
        e.url = url_helpers.meeting_url(meeting)
        e.summary = "[#{meeting.project.name}] #{meeting.title}"
        e.description = "[#{meeting.project.name}] #{I18n.t(:label_meeting)}: #{meeting.title}"
        e.uid = meeting.uid
        e.organizer = ical_organizer
        e.location = meeting.location.presence
        e.status = if cancelled
                     "CANCELLED"
                   else
                     "CONFIRMED"
                   end

        add_attendees(event: e, meeting: meeting)
      end
    end

    def add_series_event(recurring_meeting:, cancelled: false) # rubocop:disable Metrics/AbcSize
      calendar.event do |e|
        e.uid = recurring_meeting.uid
        e.summary = "[#{recurring_meeting.project.name}] #{recurring_meeting.title}"
        e.description = "[#{recurring_meeting.project.name}] #{I18n.t(:label_meeting_series)}: #{recurring_meeting.title}"
        e.organizer = ical_organizer

        e.rrule = recurring_meeting.schedule.rrules.first.to_ical # We currently only have one recurrence rule
        e.dtstart = ical_datetime(recurring_meeting.template.start_time)
        e.dtend = ical_datetime(recurring_meeting.template.end_time)
        e.url = url_helpers.project_recurring_meeting_url(recurring_meeting.project, recurring_meeting)
        e.location = recurring_meeting.template.location.presence
        e.status = if cancelled
                     "CANCELLED"
                   else
                     "CONFIRMED"
                   end

        add_attendees(event: e, meeting: recurring_meeting.template)

        # Add exceptions for all cancelled recurrences
        set_excluded_recurrence_dates(event: e, recurring_meeting: recurring_meeting)
      end

      # Add single events for all occurrences
      add_instantiated_occurences(recurring_meeting: recurring_meeting)
    end

    def add_single_recurring_occurence(scheduled_meeting:) # rubocop:disable Metrics/AbcSize
      recurring_meeting = scheduled_meeting.recurring_meeting
      meeting = scheduled_meeting.meeting

      calendar.event do |e|
        e.uid = recurring_meeting.uid
        e.summary = "[#{recurring_meeting.project.name}] #{recurring_meeting.title}"
        e.description = "[#{recurring_meeting.project.name}] #{I18n.t(:label_meeting_series)}: #{recurring_meeting.title}"
        e.organizer = ical_organizer

        e.recurrence_id = ical_datetime(scheduled_meeting.start_time)
        e.dtstart = ical_datetime(meeting.start_time)
        e.dtend = ical_datetime(meeting.end_time)
        e.url = url_helpers.project_meeting_url(meeting.project, meeting)
        e.location = meeting.location.presence
        e.sequence = meeting.lock_version

        add_attendees(event: e, meeting: meeting)
        e.status = if scheduled_meeting.cancelled?
                     "CANCELLED"
                   else
                     "CONFIRMED"
                   end
      end
    end

    def update_calendar_status(cancelled:)
      if cancelled
        calendar.cancel
      else
        calendar.request
      end
    end

    def to_ical
      calendar_timezones.each do |ical_tzinfo|
        calendar.add_timezone(ical_tzinfo)
      end

      calendar.to_ical
    end

    private

    def build_icalendar
      ::Icalendar::Calendar.new.tap do |calendar|
        calendar.prodid = "-//OpenProject GmbH//#{OpenProject::VERSION}//Meeting//EN"
      end
    end

    def add_timezone_definition(time)
      calendar_timezones << timezone.tzinfo.ical_timezone(time)
    end

    def add_attendees(event:, meeting:)
      meeting.participants.includes(:user).find_each do |participant|
        user = participant.user
        next unless user

        address = Icalendar::Values::CalAddress.new(
          "mailto:#{user.mail}",
          {
            "CN" => user.name,
            "EMAIL" => user.mail,
            "PARTSTAT" => "NEEDS-ACTION",
            "RSVP" => "TRUE",
            "CUTYPE" => "INDIVIDUAL",
            "ROLE" => "REQ-PARTICIPANT"
          }
        )

        event.append_attendee(address)
      end
    end

    def tzid
      @tzid ||= timezone.tzinfo.canonical_identifier
    end

    def ical_datetime(time)
      time_in_time_zone = time.in_time_zone(timezone)
      add_timezone_definition(time_in_time_zone)
      Icalendar::Values::DateTime.new time_in_time_zone, "tzid" => tzid
    end

    def ical_organizer
      Icalendar::Values::CalAddress.new("mailto:#{Setting.mail_from}", cn: Setting.app_title)
    end

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticUrlHelpers.new
    end

    # Methods for recurrence meetings
    def add_instantiated_occurences(recurring_meeting:)
      upcoming_instantiated_schedules(recurring_meeting).find_each do |scheduled_meeting|
        add_single_recurring_occurence(scheduled_meeting:)
      end
    end

    def set_excluded_recurrence_dates(event:, recurring_meeting:)
      event.exdate = recurring_meeting
        .scheduled_meetings
        .cancelled
        .pluck(:start_time)
        .map { ical_datetime(it) }
    end

    def upcoming_instantiated_schedules(recurring_meeting)
      recurring_meeting
        .scheduled_meetings
        .not_cancelled
        .instantiated
        .includes(meeting: [:project], recurring_meeting: [:project])
    end
  end
end
