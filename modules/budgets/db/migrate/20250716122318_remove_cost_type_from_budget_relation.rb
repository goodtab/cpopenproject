# frozen_string_literal: true

class RemoveCostTypeFromBudgetRelation < ActiveRecord::Migration[8.0]
  def change
    remove_reference(:budget_relations, :cost_type, foreign_key: true)
  end
end
