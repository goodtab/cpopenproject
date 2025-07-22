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

module OpenIDConnect
  module Providers
    class GroupMappingForm < BaseForm
      include Redmine::I18n

      class << self
        def form_data
          {
            controller: "openid-connect--group-sync-form"
          }
        end
      end

      form do |f|
        f.check_box(
          name: :sync_groups,
          label: OpenIDConnect::Provider.human_attribute_name(:sync_groups),
          caption: I18n.t("openid_connect.instructions.group_sync"),
          disabled: provider.seeded_from_env?,
          data: {
            action: "openid-connect--group-sync-form#updateFormInputs",
            "openid-connect--group-sync-form-target": "enabledCheckbox"
          }
        )

        f.group(data: { "openid-connect--group-sync-form-target": "inputsWrapper" }) do |group|
          group.text_field(
            name: :groups_claim,
            label: OpenIDConnect::Provider.human_attribute_name(:groups_claim),
            caption: I18n.t("openid_connect.instructions.groups_claim"),
            input_width: :large,
            disabled: provider.seeded_from_env?
          )

          group.html_content do
            render(Primer::Beta::Text.new) { I18n.t("openid_connect.instructions.group_regexes_detail").html_safe }
          end

          group.text_area(
            name: :group_regexes,
            rows: 5,
            label: I18n.t("openid_connect.providers.label_group_regexes"),
            caption: link_translate("openid_connect.instructions.group_regexes", links: {
                                      docs_url: ::OpenProject::Static::Links.url_for(:sysadmin_docs, :oidc_groups)
                                    }),
            disabled: provider.seeded_from_env?,
            required: false,
            input_width: :large,
            value: model.group_regexes.join("\n")
          )
        end
      end
    end
  end
end
