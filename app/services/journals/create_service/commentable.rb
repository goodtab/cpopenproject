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

class Journals::CreateService
  class Commentable < Association
    def associated?
      journable.respond_to?(:comments)
    end

    def cleanup_predecessor(predecessor)
      cleanup_predecessor_for(predecessor,
                              "comments_journals",
                              :journal_id,
                              :id)
    end

    def insert_sql
      sanitize(<<~SQL.squish, journable_id:, journable_class_name:)
        INSERT INTO
          comments_journals (
            journal_id,
            comment_id
          )
        SELECT
          #{id_from_inserted_journal_sql},
          comments.id
        FROM comments
        WHERE
          #{only_if_created_sql}
          AND comments.commented_id = :journable_id
      SQL
    end

    def changes_sql
      sanitize(<<~SQL.squish, journable_id:, container_type: journable_class_name)
        SELECT
          max_journals.journable_id
        FROM
          max_journals
        LEFT OUTER JOIN
          comments_journals
        ON
          comments_journals.journal_id = max_journals.id
        FULL JOIN
          (SELECT *
           FROM comments
           WHERE comments.commented_id = :journable_id) comments
        ON
          comments.id = comments_journals.comment_id
        WHERE
          (comments.id IS NULL AND comments_journals.comment_id IS NOT NULL)
          OR (comments_journals.comment_id IS NULL AND comments.id IS NOT NULL)
      SQL
    end
  end
end
