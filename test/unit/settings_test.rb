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

require_relative "../test_helper"

class SettingsTest < ActiveSupport::TestCase
  test "an upgrade with nothing stored changes nothing: tiles only, right column, times kept" do
    settings = RubylodeHome::Settings.new(nil)

    assert_equal "tiles", settings.welcome_page_content
    refute settings.welcome_page_tickets?
    assert_equal "right", settings.welcome_page_column
    refute settings.dates_without_times?
  end

  test "stored values are read" do
    settings = RubylodeHome::Settings.new("welcome_page_content" => "tickets", "welcome_page_column" => "left",
                                                    "dates_without_times" => "1")

    assert settings.welcome_page_tickets?
    assert_equal "left", settings.welcome_page_column
    assert settings.dates_without_times?
  end

  test "a stored value that is not a choice counts as the default" do
    settings = RubylodeHome::Settings.new("welcome_page_content" => "everything", "welcome_page_column" => "middle")

    assert_equal "tiles", settings.welcome_page_content
    assert_equal "right", settings.welcome_page_column
  end
end
