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

class PluginSettingsTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles

  SETTINGS_PATH = "/settings/plugin/redmine_rubylode_home".freeze

  setup do
    Setting.send(:"plugin_#{RedmineRubylodeHome::PLUGIN_ID}=", RedmineRubylodeHome::Defaults::SETTINGS.dup)
  end

  def stored
    Setting.send(:"plugin_#{RedmineRubylodeHome::PLUGIN_ID}")
  end

  test "the settings page opens with every field at its default" do
    log_user("admin", "admin")
    get SETTINGS_PATH

    assert_response :success
    assert_select "select[name=?] option[selected][value=?]", "settings[welcome_page_content]", "tiles"
    assert_select "select[name=?] option[selected][value=?]", "settings[welcome_page_column]", "right"
    assert_select "input[type=checkbox][name=?]:not([checked])", "settings[dates_without_times]"
  end

  test "good settings are saved" do
    log_user("admin", "admin")
    post SETTINGS_PATH, params: { settings: { "welcome_page_content" => "tickets", "welcome_page_column" => "left", "dates_without_times" => "1" } }

    assert_redirected_to SETTINGS_PATH
    assert_equal "tickets", stored["welcome_page_content"]
    assert_equal "left", stored["welcome_page_column"]
    assert_equal "1", stored["dates_without_times"]
  end

  test "a bad choice shows the problem, keeps what was posted and saves nothing" do
    log_user("admin", "admin")
    post SETTINGS_PATH, params: { settings: { "welcome_page_content" => "everything", "welcome_page_column" => "left", "dates_without_times" => "1" } }

    assert_response :unprocessable_entity
    assert_select "#errorExplanation li", text: /Welcome page content/
    assert_select "select[name=?] option[selected][value=?]", "settings[welcome_page_column]", "left"
    assert_equal "tiles", stored["welcome_page_content"], "nothing was saved"
    assert_equal "0", stored["dates_without_times"]
  end

  test "a person who is not an administrator cannot open the page" do
    log_user("jsmith", "jsmith")
    get SETTINGS_PATH

    assert_response :forbidden
  end
end
