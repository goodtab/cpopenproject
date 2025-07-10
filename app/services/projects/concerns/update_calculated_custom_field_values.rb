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
  module UpdateCalculatedCustomFieldValues
    private

    def before_perform(call)
      super.tap do
        changed_custom_values = model.custom_values.select(&:changed?)

        if changed_custom_values.present?
          changed_cf_ids = changed_custom_values.map(&:custom_field_id)
          affected_cfs = model.available_custom_fields.affected_calculated_fields(changed_cf_ids)

          update_calculated_value_fields(affected_cfs) if affected_cfs.present?
        end
      end
    end

    def update_calculated_value_fields(cfs)
      given = calculated_value_fields_referenced_values(cfs)
      to_compute = cfs.to_h { [it.column_name, it.formula_string] }

      calculator = Dentaku::Calculator.new
      calculator.store(given)
      result = calculator.solve(to_compute) { nil }.transform_keys { it.delete_prefix("cf_") }

      model.custom_field_values = result
    end

    def calculated_value_fields_referenced_values(cfs)
      given_cf_ids = cfs.flat_map(&:formula_referenced_custom_field_ids).uniq - cfs.map(&:id)
      model
        .custom_field_values
        .select { it.custom_field_id.in?(given_cf_ids) }
        .to_h { [it.custom_field.column_name, it.typed_value] }
    end
  end
end
