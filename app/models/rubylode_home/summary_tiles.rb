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
  # The four numbers at the top of the page. Due this week and overdue also carry their share of the open
  # tickets assigned to the person, for the small bar under the number.
  class SummaryTiles
    Tile = Struct.new(:key, :count, :share_percent, :tone)

    def initialize(assigned_open:, due_this_week:, overdue:, watched:)
      @assigned_open = assigned_open
      @due_this_week = due_this_week
      @overdue = overdue
      @watched = watched
    end

    def tiles
      [
        Tile.new(:assigned_open, @assigned_open, nil, :calm),
        Tile.new(:due_this_week, @due_this_week, share_of_assigned(@due_this_week), :calm),
        Tile.new(:overdue, @overdue, share_of_assigned(@overdue), @overdue.positive? ? :warning : :calm),
        Tile.new(:watched, @watched, nil, :calm)
      ]
    end

    private

    def share_of_assigned(count)
      return nil if @assigned_open.zero?

      (count * 100.0 / @assigned_open).round
    end
  end
end
