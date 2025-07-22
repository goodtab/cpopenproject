# frozen_string_literal: true

class CreateCommentsJournals < ActiveRecord::Migration[8.0]
  def change
    # rubocop:disable Rails/CreateTableWithTimestamps
    create_table :comments_journals do |t|
      t.belongs_to :journal, null: false, foreign_key: true
      t.belongs_to :comment, null: false
    end
    # rubocop:enable Rails/CreateTableWithTimestamps
  end
end
