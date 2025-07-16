# frozen_string_literal: true

class UniqueBudgetRelationChild < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    remove_index :budget_relations, :child_budget_id, if_exists: true, algorithm: :concurrently
    add_index :budget_relations, :child_budget_id, unique: true, algorithm: :concurrently
  end
end
