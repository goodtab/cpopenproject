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

RSpec.describe OpenProject::Static::Links do
  describe ".url_for" do
    subject { described_class.url_for(*args) }

    let(:args) { %i[enterprise_features board_view] }

    it "resolves the URL stored in the href" do
      expect(subject).to eq("https://www.openproject.org/docs/user-guide/agile-boards/#action-boards-enterprise-add-on")
    end

    context "when the URL has localized versions" do
      let(:args) { %i[enterprise_features attribute_highlighting] }

      it "resolves the default locale" do
        expect(subject).to eq("https://www.openproject.org/docs/user-guide/work-packages/work-package-table-configuration/#attribute-highlighting-enterprise-add-on")
      end

      context "and when asking for a supported locale" do
        around do |example|
          I18n.with_locale(:de) do
            example.run
          end
        end

        it "resolves the queried locale" do
          expect(subject).to eq("https://www.openproject.org/de/docs/nutzungshandbuch/arbeitspakete/arbeitspaket-tabellen-konfiguration/#attribute-hervorheben-enterprise-add-on")
        end
      end
    end
  end
end
