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

# dlopper (password foo) is a member of the public project 1 only; project 2 is private and he is not in it.
class WelcomeTicketsTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows, :journals, :journal_details, :watchers, :groups_users,
           :user_preferences, :versions

  def setup
    @person = User.find(3)
    Issue.update_all(assigned_to_id: nil)
    Watcher.delete_all
    configure("welcome_page_content" => "tickets")
  end

  def teardown
    Setting.send(:"plugin_#{RubylodeHome::Settings::PLUGIN_ID}=", RubylodeHome::Settings::DEFAULTS.dup)
  end

  def configure(overrides)
    Setting.send(:"plugin_#{RubylodeHome::Settings::PLUGIN_ID}=", RubylodeHome::Settings::DEFAULTS.merge(overrides))
  end

  def assigned_issue(subject, due: nil, project_id: 1, priority_id: 5, **attributes)
    issue = Issue.generate!(project_id: project_id, subject: subject, due_date: due, start_date: nil, priority_id: priority_id, **attributes)
    issue.update_columns(assigned_to_id: @person.id)
    issue
  end

  def sign_in
    log_user("dlopper", "foo")
  end

  def sql_queries_while
    count = 0
    counter = lambda do |_name, _start, _finish, _id, payload|
      count += 1 unless payload[:name].in?(%w[SCHEMA CACHE]) || payload[:cached]
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  test "with the tickets setting a signed-in person sees the tiles and their assigned tickets in the right column" do
    assigned_issue("Fix the gate", due: @person.today - 2)
    sign_in
    get "/"

    assert_response :success
    assert_select ".splitcontentleft .rubylode-home-welcome .rubylode-home-tile", 4
    assert_select ".splitcontentright [data-rubylode-home='welcome-tickets'] [data-card='assigned']" do
      assert_select ".rubylode-home-issue-subject", text: "Fix the gate"
    end
    assert_select ".splitcontentleft [data-rubylode-home='welcome-tickets']", count: 0
  end

  test "the column setting moves the tickets to the left, below the tiles" do
    configure("welcome_page_content" => "tickets", "welcome_page_column" => "left")
    assigned_issue("Fix the gate")
    sign_in
    get "/"

    assert_select ".splitcontentleft [data-rubylode-home='welcome-tickets']"
    assert_select ".splitcontentright [data-rubylode-home='welcome-tickets']", count: 0
    assert_operator response.body.index("rubylode-home-welcome\""), :<, response.body.index("welcome-tickets")
  end

  test "with the default setting the welcome page is as before: tiles only" do
    configure({})
    assigned_issue("Fix the gate")
    sign_in
    get "/"

    assert_select ".rubylode-home-welcome .rubylode-home-tile", 4
    assert_select "[data-rubylode-home='welcome-tickets']", count: 0
  end

  test "each row shows the id, subject, status, priority chip, due badge and milestone when set" do
    version = Version.create!(project_id: 1, name: "Spring release")
    issue = assigned_issue("Fix the gate", due: @person.today - 2, priority_id: 7, fixed_version: version)
    assigned_issue("Paint the fence")
    sign_in
    get "/"

    assert_select ".rubylode-home-issue-row--overdue" do
      assert_select ".rubylode-home-issue-id", text: "##{issue.id}"
      assert_select ".rubylode-home-issue-subject", text: "Fix the gate"
      assert_select ".rubylode-home-chip--status"
      assert_select ".rubylode-home-chip--priority"
      assert_select ".rubylode-home-due--overdue", text: /overdue/
      assert_select ".rubylode-home-milestone", text: "Spring release"
    end
    assert_select ".rubylode-home-milestone", 1
  end

  test "the grouping control switches between project and due date on the welcome page" do
    assigned_issue("Fix the gate", due: @person.today - 2)
    sign_in
    get "/"
    assert_select ".rubylode-home-group-title a[href*='/projects/']"
    assert_select ".rubylode-home-grouping-option[href='/?group=due_date']"

    get "/", params: { group: "due_date" }
    assert_select ".rubylode-home-group[data-group='overdue']"
    assert_select ".rubylode-home-grouping-option[aria-current='true']", text: "Due date"
  end

  test "only open tickets the person may see are listed" do
    assigned_issue("Visible one")
    assigned_issue("Hidden one", project_id: 2)
    assigned_issue("Closed one").update_columns(status_id: IssueStatus.find_by!(is_closed: true).id)
    sign_in
    get "/"

    assert_select ".rubylode-home-welcome-tickets .rubylode-home-issue-subject", text: "Visible one"
    assert_select ".rubylode-home-welcome-tickets .rubylode-home-issue-subject", text: "Hidden one", count: 0
    assert_select ".rubylode-home-welcome-tickets .rubylode-home-issue-subject", text: "Closed one", count: 0
  end

  test "the list is capped, with a link that says how many are shown and how many exist" do
    total = RubylodeHome::HomePage::ASSIGNED_LIMIT + 3
    total.times { |index| assigned_issue("Ticket #{index}") }
    sign_in
    get "/"

    assert_select ".rubylode-home-welcome-tickets .rubylode-home-issue-row", RubylodeHome::HomePage::ASSIGNED_LIMIT
    assert_select ".rubylode-home-welcome-tickets .rubylode-home-more a[href*='/issues']",
                  text: "Showing #{RubylodeHome::HomePage::ASSIGNED_LIMIT} of #{total}. See them all in the issue list."
  end

  test "a hostile subject, project name and milestone name are escaped" do
    hostile = "<script>alert(1)</script>"
    Project.find(1).update_columns(name: "<b>proj</b>")
    version = Version.create!(project_id: 1, name: "<img src=x onerror=alert(2)>")
    assigned_issue(hostile, fixed_version: version)
    sign_in
    get "/"

    refute_includes response.body, "<script>alert(1)</script>"
    refute_includes response.body, "<img src=x onerror"
    refute_includes response.body, "<b>proj</b>"
    assert_select ".rubylode-home-welcome-tickets .rubylode-home-issue-subject", text: hostile
  end

  test "an anonymous visitor gets no tickets block" do
    get "/"
    assert_response :success
    assert_select "[data-rubylode-home='welcome-tickets']", count: 0
  end

  test "the number of queries does not grow with the number of tickets" do
    versions = 3.times.map { |index| Version.create!(project_id: 1, name: "Milestone #{index}") }
    sign_in
    3.times { |index| assigned_issue("Few #{index}", due: @person.today + index, fixed_version: versions[index]) }
    get "/"
    few = sql_queries_while { get "/" }

    20.times { |index| assigned_issue("Many #{index}", due: @person.today - index, fixed_version: versions[index % 3]) }
    many = sql_queries_while { get "/" }

    assert_response :success
    assert_operator many, :<=, few, "queries for a few tickets: #{few}, for many: #{many}"
    assert_operator css_select(".rubylode-home-welcome-tickets .rubylode-home-issue-row").size, :>=, 20
  end

  test "the classic view of the My page is untouched by the setting" do
    assigned_issue("Fix the gate")
    sign_in
    get "/my/page", params: { view: "classic" }

    assert_response :success
    assert_select "[data-rubylode-home]", count: 0
    assert_select "#list-top"
  end
end
