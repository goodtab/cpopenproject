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

RSpec.describe Types::Patterns::TokenPropertyMapper do
  shared_let(:responsible) { create(:user, firstname: "Responsible") }
  shared_let(:assignee) { create(:user, firstname: "Assignee") }
  shared_let(:parent_assignee) { create(:user, firstname: "Parent", lastname: "Assignee") }

  shared_let(:category) { create(:category) }

  shared_let(:project) { create(:project, parent: create(:project), status_code: 1, status_explanation: "A Mess") }

  shared_let(:work_package_parent) do
    create(:work_package, project:, category:, start_date: Date.yesterday, estimated_hours: 120,
                          remaining_hours: 80, due_date: 3.months.from_now, assigned_to: parent_assignee)
  end

  shared_let(:work_package) do
    create(:work_package, responsible:, project:, category:, due_date: 1.month.from_now, assigned_to: assignee,
                          parent: work_package_parent, start_date: Time.zone.today, estimated_hours: 30,
                          remaining_hours: 25)
  end

  shared_let(:string_custom_field) do
    create(:string_wp_custom_field).tap do |custom_field|
      project.work_package_custom_fields << custom_field
      work_package.type.custom_fields << custom_field
    end
  end

  shared_let(:mult_list_custom_field) do
    create(:multi_list_wp_custom_field).tap do
      project.work_package_custom_fields << it
      work_package.type.custom_fields << it

      work_package.send(:"custom_field_#{it.id}=", it.possible_values.take(2))
      work_package.save
    end
  end

  shared_let(:not_activated_custom_field) do
    create(:boolean_wp_custom_field).tap do |custom_field|
      work_package.type.custom_fields << custom_field
    end
  end

  described_class::TOKEN_PROPERTY_MAP.each_pair do |key, details|
    it "the token named #{key} resolves successfully" do
      expect { details[:fn].call(work_package) }.not_to raise_error
      expect(details[:fn].call(work_package)).not_to be_nil
    end
  end

  it "multi value fields are supported" do
    function = described_class.new.fetch :"custom_field_#{mult_list_custom_field.id}"
    expect(function.call(work_package)).to eq(%w[A B])
  end

  it "must return nil if custom field is not activated in project" do
    function = described_class.new.fetch :"custom_field_#{not_activated_custom_field.id}"
    expect { function.call(work_package) }.not_to raise_error
    expect(function.call(work_package)).to be_nil
  end

  it "returns all possible tokens" do
    cf = string_custom_field
    tokens = described_class.new.tokens_for_type(work_package.type)

    expect(tokens.keys).to match_array(%i[work_package project parent])
    expect(tokens[:project][:project_status]).to eq(Project.human_attribute_name(:status_code))
    expect(tokens[:work_package][:"custom_field_#{cf.id}"]).to eq(cf.name)
  end
end
