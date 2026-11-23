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

class LinksTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows, :journals, :journal_details, :watchers, :groups_users,
           :user_preferences

  LINKS = "Status | https://status.example.com\nWiki | http://wiki.example.com/home\nBad | javascript:alert(1)".freeze

  def teardown
    configure({})
  end

  def configure(overrides)
    Setting.send(:"plugin_#{RubylodeHome::Settings::PLUGIN_ID}=", RubylodeHome::Settings::DEFAULTS.merge(overrides))
  end

  def sign_in
    log_user("dlopper", "foo")
  end

  test "the welcome page shows the valid links as pills under the title, before the Your work block" do
    configure("links" => LINKS, "links_title" => "Team services")
    sign_in
    get "/"

    assert_response :success
    assert_select "[data-rubylode-home='links'] .rubylode-home-links-title", text: "Team services"
    assert_select "[data-rubylode-home='links'] a.rubylode-home-link-pill", 2
    assert_select "a.rubylode-home-link-pill[href='https://status.example.com']", text: "Status"
    assert_select "a.rubylode-home-link-pill[href^='javascript']", count: 0
    assert_operator response.body.index("data-rubylode-home=\"links\""), :<, response.body.index("data-rubylode-home=\"welcome\"")
  end

  test "My page shows the links near the top, above the tiles" do
    configure("links" => LINKS)
    sign_in
    get "/my/page"

    assert_response :success
    assert_select "[data-rubylode-home='links'] .rubylode-home-links-title", text: "Services"
    assert_select "[data-rubylode-home='links'] a.rubylode-home-link-pill", 2
    assert_operator response.body.index("data-rubylode-home=\"links\""), :<, response.body.index("rubylode-home-tiles")
  end

  test "the links open in a new tab and do not leak the opener" do
    configure("links" => LINKS)
    sign_in
    get "/my/page"

    assert_select "a.rubylode-home-link-pill[target='_blank'][rel='noopener noreferrer']", 2
  end

  test "a name with markup is escaped" do
    configure("links" => "<script>alert(1)</script> | https://example.com")
    sign_in
    get "/"

    refute_includes response.body, "<script>alert(1)</script>"
    assert_select "a.rubylode-home-link-pill", text: "<script>alert(1)</script>"
  end

  test "with no links neither page draws the section" do
    configure({})
    sign_in
    get "/"
    assert_select "[data-rubylode-home='links']", count: 0
    get "/my/page"
    assert_select "[data-rubylode-home='links']", count: 0
  end

  test "links that are all invalid draw nothing" do
    configure("links" => "Bad | javascript:alert(1)\nAlso bad")
    sign_in
    get "/my/page"

    assert_select "[data-rubylode-home='links']", count: 0
  end

  test "an empty title falls back to Services" do
    configure("links" => LINKS, "links_title" => "  ")
    sign_in
    get "/my/page"

    assert_select ".rubylode-home-links-title", text: "Services"
  end

  test "the classic view of My page does not draw the links" do
    configure("links" => LINKS)
    sign_in
    get "/my/page", params: { view: "classic" }

    assert_select "[data-rubylode-home='links']", count: 0
  end

  test "an anonymous visitor does not get the links on the welcome page" do
    configure("links" => LINKS)
    get "/"

    assert_response :success
    assert_select "[data-rubylode-home='links']", count: 0
  end
end
