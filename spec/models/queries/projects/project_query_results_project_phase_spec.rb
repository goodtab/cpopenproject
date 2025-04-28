# frozen_string_literal: true

# -- copyright
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
# ++

require "spec_helper"

RSpec.describe ProjectQuery, "results of a project phase filter" do
  let(:instance) { described_class.new }
  let(:filter_key) { "project_phase_#{stage.definition_id}" }

  shared_let(:view_role) { create(:project_role, permissions: %i[view_project_phases]) }

  shared_let(:phase_start_date) { Date.parse("2025-02-07") }
  shared_let(:phase_finish_date) { Date.parse("2025-02-17") }
  shared_let(:project_with_phase) { create(:project, name: "Project with stage") }
  shared_let(:stage) do
    create(:project_phase, project: project_with_phase, start_date: phase_start_date, finish_date: phase_finish_date)
  end

  # This is added to ensure that the filter only works on the stage provided.
  shared_let(:project_with_rival_phase) { create(:project, name: "Project with rival stage") }
  shared_let(:rival_stage) do
    create(:project_phase, project: project_with_rival_phase, start_date: phase_start_date, finish_date: phase_finish_date)
  end

  shared_let(:project_without_phase) { create(:project, name: "Project without phase") }

  shared_let(:user) do
    create(:user, member_with_permissions: {
             project_with_phase => %i[view_project_phases],
             project_with_rival_phase => %i[view_project_phases],
             project_without_phase => %i[view_project_phases]
           })
  end

  current_user { user }

  # rubocop:disable RSpec/ScatteredSetup
  def self.disable_phase
    before do
      Project::Phase.update_all(active: false)
    end
  end

  def self.remove_phase_dates
    before do
      stage.update_columns(finish_date: nil, start_date: nil)
    end
  end

  def self.remove_permissions
    before do
      # We keep the permission within the Project without phases so that the filter itself is available
      # but we check that the filter does not return values.
      RolePermission
        .where(role_id: Role.joins(:member_roles)
                            .where(member_roles: { member_id: Member.where(project: [project_with_phase]) }))
        .where(permission: :view_project_phases)
        .destroy_all
    end
  end
  # rubocop:enable RSpec/ScatteredSetup

  context "with a =d (on) operator" do
    before do
      instance.where(filter_key, "=d", values)
    end

    context "when filtering in the middle of the stage" do
      let(:values) { [(phase_start_date + ((phase_finish_date - phase_start_date) / 2)).to_s] }

      it "returns the project whose stage is covering an interval including the date" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when filtering on the first day of the stage" do
      let(:values) { [phase_start_date.to_s] }

      it "returns the project whose stage begins on that date" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when filtering on the last day of the stage" do
      let(:values) { [phase_finish_date.to_s] }

      it "returns the project whose stage ends on that date" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when filtering before the stage" do
      let(:values) { [(phase_start_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering after the stage" do
      let(:values) { [(phase_finish_date + 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the stage has no dates" do
      let(:values) { [phase_finish_date.to_s] }

      remove_phase_dates

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering in the middle of the stage but with the stage being inactive" do
      let(:values) { [(phase_start_date + ((phase_finish_date - phase_start_date) / 2)).to_s] }

      disable_phase

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when filtering in the middle of the stage but without permissions" do
      let(:values) { [(phase_start_date + ((phase_finish_date - phase_start_date) / 2)).to_s] }

      remove_permissions

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end
  end

  context "with a t (today) operator" do
    before do
      instance.where(filter_key, "t", [])
    end

    context "when being in the middle of the stage" do
      it "returns the project whose stage is currently running" do
        Timecop.travel((phase_start_date + (phase_finish_date - phase_start_date)).noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being on the first day of the stage" do
      it "returns the project whose stage begins on that date" do
        Timecop.travel(phase_start_date.noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being on the last day of the stage" do
      it "returns the project whose stage begins on that date" do
        Timecop.travel(phase_finish_date.noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being before the stage" do
      it "returns no project" do
        Timecop.travel(phase_start_date.noon - 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being after the stage" do
      it "returns no project" do
        Timecop.travel(phase_finish_date.noon + 1.day) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when the stage has no dates" do
      remove_phase_dates

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when being in the middle of the stage but with the stage being disabled" do
      disable_phase

      it "returns no project" do
        Timecop.travel((phase_start_date + (phase_finish_date - phase_start_date)).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the stage but without permissions" do
      remove_permissions

      it "returns no project" do
        Timecop.travel((phase_start_date + (phase_finish_date - phase_start_date)).noon) do
          expect(instance.results).to be_empty
        end
      end
    end
  end

  context "with a w (this week) operator" do
    before do
      instance.where(filter_key, "w", [])
    end

    context "when being in the middle of the stage" do
      it "returns the project whose stage is currently running" do
        Timecop.travel((phase_start_date + 3.days).noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when the current week overlaps the beginning of the stage" do
      it "returns the project whose stage begins within the week" do
        Timecop.travel((phase_start_date - 1.day).noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when the current week overlaps the end of the stage" do
      it "returns the project whose stage begins within the week" do
        Timecop.travel(phase_finish_date.noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being before the stage" do
      it "returns no project" do
        Timecop.travel(phase_start_date.noon - 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being after the stage" do
      it "returns no project" do
        Timecop.travel(phase_finish_date.noon + 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when the stage has no dates" do
      remove_phase_dates

      it "returns no project" do
        Timecop.travel(phase_finish_date.noon + 7.days) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the stage but with the stage disabled" do
      disable_phase

      it "returns no project" do
        Timecop.travel((phase_start_date + 3.days).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being in the middle of the stage but without permissions" do
      remove_permissions

      it "returns no project" do
        Timecop.travel((phase_start_date + 3.days).noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being on Monday, the stage ends on Sunday and the week is configured to start on Sunday",
            with_settings: { start_of_week: 7 } do
      before do
        stage.update_column(:finish_date, Date.parse("2025-02-16"))
      end

      it "returns the project whose stage has ended within the current week" do
        Timecop.travel(Date.parse("2025-02-17").noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being on Monday, the stage ends on Sunday and the week is configured to start on Monday",
            with_settings: { start_of_week: 1 } do
      before do
        stage.update_column(:finish_date, Date.parse("2025-02-16"))
      end

      it "returns no project as the stage ended in the week before" do
        Timecop.travel(Date.parse("2025-02-17").noon) do
          expect(instance.results).to be_empty
        end
      end
    end

    context "when being on Sunday, the stage ends on Monday and the week is configured to start on Monday",
            with_settings: { start_of_week: 1 } do
      before do
        stage.update_column(:finish_date, Date.parse("2025-02-17"))
      end

      it "returns the project whose stage has ended within the current week" do
        Timecop.travel(Date.parse("2025-02-23").noon) do
          expect(instance.results).to contain_exactly(project_with_phase)
        end
      end
    end

    context "when being on Sunday, the stage ends on Monday and the week is configured to start on Sunday",
            with_settings: { start_of_week: 7 } do
      before do
        stage.update_column(:finish_date, Date.parse("2025-02-17"))
      end

      it "returns no project as the stage ended in the week before" do
        Timecop.travel(Date.parse("2025-02-23").noon) do
          expect(instance.results).to be_empty
        end
      end
    end
  end

  context "with a <>d (between) operator" do
    before do
      instance.where(filter_key, "<>d", values)
    end

    context "when encompassing the stage completely" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date + 1.day).to_s] }

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when encompassing the stage precisely" do
      let(:values) { [phase_start_date.to_s, phase_finish_date.to_s] }

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when the values overlap the stage's start date but not the end date" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the values overlap the stage's end date but not the start date" do
      let(:values) { [(phase_start_date + 1.day).to_s, phase_finish_date.to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the values are between the start and the end date of the stage" do
      let(:values) { [(phase_start_date + 1.day).to_s, (phase_finish_date - 1.day).to_s] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when only the lower value is provided and that one is before the stage's start date" do
      let(:values) { [(phase_start_date - 1.day).to_s, ""] }

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when only the lower value is provided and that one is on the stage's start date" do
      let(:values) { [phase_start_date.to_s, ""] }

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when only the lower value is provided and that one after the stage's start date" do
      let(:values) { [(phase_start_date + 1.day).to_s, ""] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when only the upper value is provided and that one is after the stage's end date" do
      let(:values) { ["", (phase_finish_date + 1.day).to_s] }

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when the stage has no dates" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date + 1.day).to_s] }

      remove_phase_dates

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when no value is provided" do
      let(:values) { ["", ""] }

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when encompassing the stage completely but with the stage disabled" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date + 1.day).to_s] }

      disable_phase

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when encompassing the stage completely but without permissions" do
      let(:values) { [(phase_start_date - 1.day).to_s, (phase_finish_date + 1.day).to_s] }

      remove_permissions

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end
  end

  context "with a !* (none) operator" do
    before do
      instance.where(filter_key, "!*", [])
    end

    context "when the phase is active but has no dates" do
      remove_phase_dates

      it "returns the project with the stage" do
        expect(instance.results).to contain_exactly(project_with_phase)
      end
    end

    context "when the stage is active and has dates" do
      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end

    context "when the stage is inactive and has no dates" do
      remove_phase_dates
      disable_phase

      it "returns no project" do
        expect(instance.results).to be_empty
      end
    end
  end
end
