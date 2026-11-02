# Rubylode Home: better home views for Redmine
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
  # When a due date counts as overdue, due this week or due soon, seen from one day.
  # first_day_of_week follows Redmine's setting: 1 is Monday, 6 Saturday, 7 (or 0) Sunday.
  class DueDateRules
    BUCKETS = %i[overdue today this_week next_week later no_due_date].freeze
    DUE_SOON_DAYS = 14

    attr_reader :today

    def initialize(today:, first_day_of_week:)
      @today = today
      @first_day_of_week = first_day_of_week.to_i % 7
    end

    def week_end
      days_since_week_start = (today.wday - @first_day_of_week) % 7
      today + (6 - days_since_week_start)
    end

    def next_week_end = week_end + 7

    def due_soon_end = today + (DUE_SOON_DAYS - 1)

    def overdue?(due_date)
      due_date.present? && due_date < today
    end

    def due_this_week?(due_date)
      due_date.present? && due_date >= today && due_date <= week_end
    end

    def due_soon?(due_date)
      due_date.present? && due_date <= due_soon_end
    end

    def days_until(due_date)
      due_date && (due_date - today).to_i
    end

    def bucket_for(due_date)
      return :no_due_date if due_date.nil?
      return :overdue if due_date < today
      return :today if due_date == today
      return :this_week if due_date <= week_end
      return :next_week if due_date <= next_week_end

      :later
    end
  end
end
