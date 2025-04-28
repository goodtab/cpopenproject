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

module EnterpriseHelper
  def write_augur_to_gon
    gon.augur_url = OpenProject::Configuration.enterprise_trial_creation_host
    gon.token_version = OpenProject::Token::VERSION
  end

  def write_trial_key_to_gon
    trial_key = Token::EnterpriseTrialKey.find_by(user_id: User.system.id)
    if trial_key
      gon.ee_trial_key = {
        value: trial_key.value,
        created: trial_key.created_at
      }
    end
  end

  def enterprise_token_plan_name(enterprise_token)
    <<~LABEL.squish
      #{I18n.t(enterprise_token.plan, scope: [:enterprise_plans], default: enterprise_token.plan.to_s.capitalize)}
      (#{I18n.t(:label_token_version)} #{enterprise_token.version})
    LABEL
  end

  def enterprise_plan_additional_features(enterprise_token)
    (enterprise_token.try(:features) || [])
      .filter_map { |feature| I18n.t(feature, scope: :"ee.features", default: nil) }
      .sort
      .join(", ")
  end
end
