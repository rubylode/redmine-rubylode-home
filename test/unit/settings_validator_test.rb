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

class SettingsValidatorTest < ActiveSupport::TestCase
  GOOD = { "welcome_page_content" => "tickets", "welcome_page_column" => "left", "dates_without_times" => "1" }.freeze

  def errors_for(overrides = {})
    RubylodeHome::SettingsValidator.errors_for(GOOD.merge(overrides))
  end

  test "good settings have no errors, and so does an empty post" do
    assert_empty errors_for
    assert_empty RubylodeHome::SettingsValidator.errors_for(nil)
    assert_empty RubylodeHome::SettingsValidator.errors_for({})
  end

  test "each setting outside its choices is refused with its own message" do
    assert_match(/Welcome page content/, errors_for("welcome_page_content" => "all").first)
    assert_match(/Column/, errors_for("welcome_page_column" => "middle").first)
    assert_match(/dates without times/i, errors_for("dates_without_times" => "yes").first)
    assert_equal 3, errors_for("welcome_page_content" => "", "welcome_page_column" => "", "dates_without_times" => "").size
  end
end
