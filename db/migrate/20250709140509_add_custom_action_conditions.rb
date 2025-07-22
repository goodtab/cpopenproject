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

class AddCustomActionConditions < ActiveRecord::Migration[7.1]
  ASSOCIATIONS = %w[Project Type Role Status].freeze

  def up
    create_table :custom_action_conditions, id: :integer do |t|
      t.references :custom_action
      t.references :conditionable, polymorphic: true, null: false
    end

    ASSOCIATIONS.each do |klass|
      condition_name = klass.downcase
      table_name = "custom_actions_#{condition_name.pluralize}"

      execute <<~SQL.squish
        INSERT INTO custom_action_conditions (custom_action_id, conditionable_id, conditionable_type)
          SELECT custom_action_id, #{condition_name}_id as conditionable_id, '#{klass}' as conditionable_type
            FROM #{table_name}
      SQL

      drop_table table_name
    end
  end

  def down
    ASSOCIATIONS.each do |klass|
      condition_name = klass.downcase
      table_name = "custom_actions_#{condition_name.pluralize}"

      create_table table_name, id: :integer do |t|
        t.references :custom_action
        t.references condition_name
      end

      execute <<~SQL.squish
        INSERT INTO #{table_name} (custom_action_id, #{condition_name}_id)
          SELECT custom_action_id, conditionable_id as #{condition_name}_id
            FROM custom_action_conditions
              WHERE conditionable_type = '#{klass}'
      SQL
    end

    drop_table :custom_action_conditions
  end
end
