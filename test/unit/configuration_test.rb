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

require_relative "../test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  test "an upgrade with nothing stored changes nothing: tiles only, right column, times kept" do
    configuration = RubylodeHome::Configuration.new(nil)

    assert_equal "tiles", configuration.welcome_page_content
    refute configuration.welcome_page_tickets?
    assert_equal "right", configuration.welcome_page_column
    refute configuration.dates_without_times?
  end

  test "stored values are read" do
    configuration = RubylodeHome::Configuration.new("welcome_page_content" => "tickets", "welcome_page_column" => "left",
                                                    "dates_without_times" => "1")

    assert configuration.welcome_page_tickets?
    assert_equal "left", configuration.welcome_page_column
    assert configuration.dates_without_times?
  end

  test "a stored value that is not a choice counts as the default" do
    configuration = RubylodeHome::Configuration.new("welcome_page_content" => "everything", "welcome_page_column" => "middle")

    assert_equal "tiles", configuration.welcome_page_content
    assert_equal "right", configuration.welcome_page_column
  end
end
