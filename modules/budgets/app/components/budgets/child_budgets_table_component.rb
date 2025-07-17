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

module Budgets
  class ChildBudgetsTableComponent < ::OpPrimer::BorderBoxTableComponent
    columns :id, :subject, :project, :relation_type, :budget_amount
    main_column :subject, :proejct, :relation_type, :budget_amount

    def sortable?
      false
    end

    def paginated?
      false
    end

    def has_actions?
      false
    end

    def empty_row_message
      I18n.t :no_results_title_text
    end

    def row_class
      Budgets::ChildBudgetsRowComponent
    end

    def mobile_title
      I18n.t(:label_budget_child_budgets)
    end

    def headers
      [
        [:id, { caption: Budget.human_attribute_name(:id) }],
        [:subject, { caption: Budget.human_attribute_name(:subject) }],
        [:project, { caption: Budget.human_attribute_name(:project) }],
        [:relation_type, { caption: BudgetRelation.human_attribute_name(:relation_type) }],
        [:budget_amount, { caption: Budget.human_attribute_name(:budget) }]
      ]
    end
  end
end
