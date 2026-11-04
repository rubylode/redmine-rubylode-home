# Rubylode Home: a home view for Redmine's My page
# Copyright (C) 2026  Nick Gorbikoff
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

module RubylodeHome
  # Prepended once to QueriesHelper, and active only while the "dates without times" setting is on. It touches Redmine's own
  # created, updated and closed columns of an issue list and the "added by" and "updated by" lines of an issue page; every other column,
  # list and page, including the columns other plugins add, goes straight to Redmine.
  module DatesWithoutTimes
    ISSUE_COLUMNS = %i[created_on updated_on closed_on].freeze
    LABELS_WITH_A_DATE = { label_added_time_by: :"rubylode_home.dates.added_by_on", label_updated_time_by: :"rubylode_home.dates.updated_by_on" }.freeze
    PAGES_WITH_HISTORY = %w[issues journals].freeze

    def column_value(column, item, value)
      return super unless dates_without_times? && item.is_a?(Issue) && ISSUE_COLUMNS.include?(column.name) && value.respond_to?(:utc)

      format_date(User.current.time_to_date(value))
    end

    # "Added by Jo 3 days ago" above an issue and its comments becomes "Added by Jo on 2026-11-02". Other labels, and the
    # "ago" lines elsewhere, stay as Redmine has them.
    def authoring(created, author, options = {})
      label = LABELS_WITH_A_DATE[options[:label] || :label_added_time_by]
      return super unless created && label && dates_without_times? && PAGES_WITH_HISTORY.include?(controller_name)

      l(label, author: link_to_user(author), date: content_tag("span", format_date(User.current.time_to_date(created)), class: "rubylode-home-date")).html_safe
    end

    private

    def dates_without_times?
      RubylodeHome::Settings.current.dates_without_times?
    end
  end
end
