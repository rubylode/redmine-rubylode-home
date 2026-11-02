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

# dlopper (password foo) is a member of the public project 1 only; project 2 is private and he is not in it.
class HomePageTest < Redmine::IntegrationTest
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows, :journals, :journal_details, :watchers, :groups_users,
           :user_preferences

  def setup
    @person = User.find(3)
    Issue.update_all(assigned_to_id: nil)
    Watcher.delete_all
  end

  def assigned_issue(subject, due: nil, project_id: 1, priority_id: 5)
    issue = Issue.generate!(project_id: project_id, subject: subject, due_date: due, start_date: nil, priority_id: priority_id)
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

  test "the plugin registers with its id, name and version" do
    plugin = Redmine::Plugin.find(:redmine_rubylode_home)
    assert_equal "Rubylode Home", plugin.name
    assert_equal "1.0.0", plugin.version
  end

  test "the My page greets the person, shows today's date, the four tiles and a new issue entry" do
    assigned_issue("Fix the gate", due: @person.today - 2)
    assigned_issue("Paint the fence", due: @person.today)
    Issue.find(1).add_watcher(@person)
    sign_in
    get "/my/page"

    assert_response :success
    assert_select "link[rel=stylesheet][href*='rubylode_home']"
    assert_select ".rubylode-home[data-rubylode-home='my-page']" do
      assert_select ".rubylode-home-greeting", text: /Dave/
      assert_select ".rubylode-home-date time[datetime='#{@person.today.iso8601}']"
      assert_select ".rubylode-home-tile", 4
      assert_select ".rubylode-home-tile[data-tile='assigned_open'] .rubylode-home-tile-count", text: "2"
      assert_select ".rubylode-home-tile[data-tile='due_this_week'] .rubylode-home-tile-count", text: "1"
      assert_select ".rubylode-home-tile[data-tile='overdue'].rubylode-home-tile--warning .rubylode-home-tile-count", text: "1"
      assert_select ".rubylode-home-tile[data-tile='watched'] .rubylode-home-tile-count", text: "1"
      assert_select "a.rubylode-home-new-issue[href='/issues/new']"
    end
  end

  test "the assigned card groups by project, marks the overdue row and shows status and unusual priority" do
    overdue = assigned_issue("Fix the gate", due: @person.today - 2, priority_id: 7)
    assigned_issue("Paint the fence")
    sign_in
    get "/my/page"

    assert_select ".rubylode-home-card[data-card='assigned']" do
      assert_select ".rubylode-home-group-title", text: /eCookbook/
      assert_select ".rubylode-home-issue-row--overdue a[href='/issues/#{overdue.id}']", text: /Fix the gate/
      assert_select ".rubylode-home-issue-row--overdue .rubylode-home-due", text: /2 days overdue/
      assert_select ".rubylode-home-issue-row--overdue .rubylode-home-chip--status", text: "New"
      assert_select ".rubylode-home-issue-row--overdue .rubylode-home-chip--priority-high", text: "Urgent"
      assert_select ".rubylode-home-chip--priority", count: 1 # Normal priority carries no chip
      assert_select "a.rubylode-home-grouping-option[aria-current='true']", text: "Project"
    end
  end

  test "grouping by due date puts the tickets under when they are due" do
    assigned_issue("Fix the gate", due: @person.today - 2)
    assigned_issue("Paint the fence")
    sign_in
    get "/my/page", params: { group: "due_date" }

    assert_select ".rubylode-home-card[data-card='assigned'] .rubylode-home-group-title", text: /Overdue/
    assert_select ".rubylode-home-card[data-card='assigned'] .rubylode-home-group-title", text: /No due date/
    assert_select "a.rubylode-home-grouping-option[aria-current='true']", text: "Due date"
  end

  test "the side cards list due soon, watched and recently updated tickets" do
    soon = assigned_issue("Fix the gate", due: @person.today + 3)
    Issue.find(1).add_watcher(@person)
    sign_in
    get "/my/page"

    assert_select ".rubylode-home-card[data-card='due_soon'] a[href='/issues/#{soon.id}']"
    assert_select ".rubylode-home-card[data-card='watched'] a[href='/issues/1']"
    assert_select ".rubylode-home-card[data-card='recently_updated'] a[href='/issues/#{soon.id}']"
    assert_select ".rubylode-home-card[data-card='activity']"
  end

  test "a ticket in a project the person cannot see stays off the page" do
    assigned_issue("Secret plan", project_id: 2, due: @person.today - 1)
    sign_in
    get "/my/page"

    assert_select ".rubylode-home", text: /Secret plan/, count: 0
    assert_select ".rubylode-home-tile[data-tile='overdue'] .rubylode-home-tile-count", text: "0"
  end

  test "with nothing assigned or watched, each card says what to do" do
    sign_in
    get "/my/page"

    assert_select ".rubylode-home-card[data-card='assigned'] .rubylode-home-empty", text: /Nothing is assigned to you/
    assert_select ".rubylode-home-card[data-card='due_soon'] .rubylode-home-empty", text: /due date/
    assert_select ".rubylode-home-card[data-card='watched'] .rubylode-home-empty", text: /Watch/
  end

  test "Redmine's own page blocks stay on the page, collapsed, with the block picker" do
    sign_in
    get "/my/page"

    assert_select "details#rubylode-home-classic-blocks:not([open])" do
      assert_select "#my-page .block-receiver"
      assert_select "#block-select"
    end
    assert_select "a[href='/my/page?view=classic']"
  end

  test "the classic view shows Redmine's page alone, with a way back" do
    sign_in
    get "/my/page", params: { view: "classic" }

    assert_response :success
    assert_select ".rubylode-home-tiles", count: 0
    assert_select "#my-page .block-receiver"
    assert_select "#block-select"
    assert_select "a.rubylode-home-back[href='/my/page']"
  end

  test "the number of queries does not grow with the number of tickets on the page" do
    sign_in
    # Enough fresh tickets that the activity card is full in both measurements, so only the ticket lists change size.
    10.times { |index| Issue.generate!(project_id: 1, subject: "Background #{index}") }
    3.times { |index| assigned_issue("Few #{index}", due: @person.today + index) }
    Issue.where(project_id: 1).limit(2).each { |issue| issue.add_watcher(@person) }
    get "/my/page"
    few = sql_queries_while { get "/my/page" }

    12.times { |index| assigned_issue("Many #{index}", due: @person.today - index) }
    Issue.where(project_id: 1).offset(2).limit(6).each { |issue| issue.add_watcher(@person) }
    many = sql_queries_while { get "/my/page" }

    assert_response :success
    # Five times the tickets may not cost a query more. (It can cost one less: a preload with nothing to load is skipped.)
    assert_operator many, :<=, few, "queries for a few tickets: #{few}, for many: #{many}"
  end

  test "the welcome page shows a signed-in person their tiles and the way to their home" do
    assigned_issue("Fix the gate", due: @person.today - 1)
    sign_in
    get "/"

    assert_select ".rubylode-home-welcome .rubylode-home-tile", 4
    assert_select ".rubylode-home-welcome a[href='/my/page']"
    assert_select "link[rel=stylesheet][href*='rubylode_home']"
  end

  test "the welcome page shows nothing extra to an anonymous visitor" do
    get "/"
    assert_select ".rubylode-home-welcome", count: 0
  end

  test "other pages do not load the stylesheet" do
    sign_in
    get "/projects"
    assert_response :success
    assert_select "link[href*='rubylode_home']", count: 0
  end

  test "the plugin shows its project address and author on the Plugins page" do
    plugin = Redmine::Plugin.find(:redmine_rubylode_home)
    readme = File.read(File.expand_path("../../README.md", __dir__))
    repository_name = readme[%r{git clone https://github\.com/rubylode/([\w-]+)\.git}, 1]
    assert_equal "redmine-rubylode-home", repository_name
    assert_equal "https://github.com/rubylode/#{repository_name}", plugin.url
    assert_equal "Rubylode", plugin.author
    assert_equal "https://github.com/rubylode", plugin.author_url
  end
end
