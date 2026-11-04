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

require File.expand_path("../test_helper", __dir__)

class SummaryTilesTest < ActiveSupport::TestCase
  def tiles(assigned_open: 20, due_this_week: 5, overdue: 2, watched: 7)
    RubylodeHome::SummaryTiles.new(assigned_open: assigned_open, due_this_week: due_this_week, overdue: overdue,
                                   watched: watched).tiles
  end

  test "four tiles in a fixed order with their counts" do
    assert_equal %i[assigned_open due_this_week overdue watched], tiles.map(&:key)
    assert_equal [20, 5, 2, 7], tiles.map(&:count)
  end

  test "due this week and overdue carry their share of the open assigned tickets, rounded" do
    shares = tiles(assigned_open: 3, due_this_week: 1, overdue: 2).to_h { |tile| [tile.key, tile.share_percent] }
    assert_equal({ assigned_open: nil, due_this_week: 33, overdue: 67, watched: nil }, shares)
  end

  test "nothing assigned means no share rather than a division by zero" do
    shares = tiles(assigned_open: 0, due_this_week: 0, overdue: 0).map(&:share_percent)
    assert_equal [nil, nil, nil, nil], shares
  end

  test "overdue tickets turn the overdue tile into a warning, otherwise every tile is calm" do
    assert_equal %i[calm calm warning calm], tiles.map(&:tone)
    assert_equal %i[calm calm calm calm], tiles(overdue: 0).map(&:tone)
  end

  # The view shows the text line when a tile has no share, which is the case when nothing is assigned.
  test "every tile has both a label and a text line, so nothing reads translation missing" do
    tiles.each do |tile|
      assert I18n.exists?(:"rubylode_home.tiles.#{tile.key}.label", :en), "label for #{tile.key}"
      assert I18n.exists?(:"rubylode_home.tiles.#{tile.key}.note", :en), "text for #{tile.key}"
    end
  end
end
