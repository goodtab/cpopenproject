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

module WorkPackage::PDFExport::Common::Badge
  class BadgeCallback
    def initialize(options)
      @color = options[:color]
      @document = options[:document]
      @radius = options[:radius]
      @offset = options[:offset] || 0
    end

    def render_behind(fragment)
      original_color = @document.fill_color
      @document.fill_color = @color
      @document.fill_rounded_rectangle([fragment.left, fragment.top + 1 + @offset], fragment.width, fragment.height + 3, @radius)
      @document.fill_color = original_color
    end
  end

  def readable_color(pdf_background_color)
    sum = [
      pdf_background_color[0..1],
      pdf_background_color[2..3],
      pdf_background_color[4..5]
    ].sum { |color_part| color_part.to_i(16) }
    lightness = sum / 3
    lightness < 130 ? "FFFFFF" : "000000"
  end

  def prawn_badge(text, color, offset: 0)
    badge = BadgeCallback.new({ color: color, radius: 8, document: pdf, offset: })
    {
      text: (Prawn::Text::NBSP * 3) + text + (Prawn::Text::NBSP * 3),
      size: 8,
      color: readable_color(color),
      callback: badge
    }
  end
end
