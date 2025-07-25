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

module Projects::Concerns
  module SetCalculatedCustomFieldValues
    private

    def set_attributes(params)
      super(params_except_calculated_fields(params)).tap do
        update_calculated_value_custom_fields
      end
    end

    def params_except_calculated_fields(params)
      custom_field_value_params = params[:custom_field_values]
      return params unless custom_field_value_params

      calculated_field_ids = model.available_custom_fields.select(&:field_format_calculated_value?).map(&:id)
      custom_field_value_params = custom_field_value_params.reject { |id, _| id.to_s.to_i.in?(calculated_field_ids) }

      params.merge(custom_field_values: custom_field_value_params)
    end

    def update_calculated_value_custom_fields
      changed_cf_ids = model.custom_values.select(&:changed?).map(&:custom_field_id)
      affected_cfs = model.available_custom_fields.affected_calculated_fields(changed_cf_ids)

      model.calculate_custom_fields(affected_cfs)
    end
  end
end
