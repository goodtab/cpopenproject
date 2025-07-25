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

module ActsAsCustomizable::CalculatedValue
  extend ActiveSupport::Concern

  included do
    def calculate_custom_fields(custom_fields)
      return if custom_fields.empty?

      given = calculated_value_fields_referenced_values(custom_fields)
      to_compute = custom_fields.to_h { [it.column_name, it.formula_str_without_patterns] }

      calculator = CustomField::CalculatedValue.calculator_instance
      calculator.store(given)
      result = calculator.solve(to_compute) { nil } # nil is the value when calculation is not possible

      self.custom_field_values = custom_fields.to_h { [it.id, result[it.column_name]] }
    end

  private

    def calculated_value_fields_referenced_values(custom_fields)
      given_cf_ids = custom_fields.flat_map(&:formula_referenced_custom_field_ids).uniq - custom_fields.map(&:id)

      custom_field_values
        .select { it.custom_field_id.in?(given_cf_ids) }
        .to_h { [it.custom_field.column_name, it.typed_value] }
    end
  end
end
