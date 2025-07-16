# frozen_string_literal: true

module Budgets
  class Engine < ::Rails::Engine
    include OpenProject::Plugins::ActsAsOpEngine

    register "budgets",
             author_url: "https://www.openproject.org",
             bundled: true do
      project_module :budgets do
        permission :view_budgets,
                   {
                     budgets: %i[index show],
                     budget_relations: %i[index]
                   },
                   permissible_on: :project
        permission :edit_budgets,
                   {
                     budgets: %i[index show edit update destroy destroy_info new create copy],
                     budget_relations: %i[index edit update new create destroy]
                   },
                   permissible_on: :project
      end

      menu :project_menu,
           :budgets,
           { controller: "/budgets", action: "index" },
           if: ->(project) { project.module_enabled?(:budgets) },
           after: :costs,
           caption: :budgets_title,
           icon: "op-budget"
    end

    patch_with_namespace :Projects, :RowComponent

    add_api_path :budget do |id|
      "#{root}/budgets/#{id}"
    end

    add_api_path :budgets_by_project do |project_id|
      "#{project(project_id)}/budgets"
    end

    add_api_path :attachments_by_budget do |id|
      "#{budget(id)}/attachments"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::Budgets::BudgetsAPI
    end

    add_api_endpoint "API::V3::Projects::ProjectsAPI", :id do
      mount ::API::V3::Budgets::BudgetsByProjectAPI
    end

    config.to_prepare do
      Budgets::Hooks::WorkPackageHook
    end

    config.to_prepare do
      OpenProject::ProjectLatestActivity.register on: "Budget"

      # Add to the budget to the costs group
      ::Type.add_default_mapping(:costs, :budget)

      ::Type.add_constraint :budget, ->(_type, project: nil) {
        project.nil? || project.module_enabled?(:budgets)
      }

      ::Queries::Register.register(::Query) do
        filter Queries::WorkPackages::Filter::BudgetFilter
      end

      ::Queries::Register.register(::ProjectQuery) do
        select Queries::Projects::Selects::BudgetPlanned
        select Queries::Projects::Selects::BudgetSpent
        select Queries::Projects::Selects::BudgetSpentRatio
        select Queries::Projects::Selects::BudgetAvailable
        select Queries::Projects::Selects::BudgetAllocated
      end
    end
  end
end
