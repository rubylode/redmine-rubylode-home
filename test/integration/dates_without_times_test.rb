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

class DatesWithoutTimesTest < Redmine::IntegrationTest
  include Redmine::I18n

  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows, :journals, :journal_details, :versions, :time_entries

  CREATED = Time.utc(2014, 3, 9, 15, 42)
  UPDATED = Time.utc(2015, 6, 1, 8, 5)
  CLOSED = Time.utc(2016, 7, 4, 23, 59)

  setup do
    Issue.delete_all
    @project = Project.find(1)
    @user = User.find_by!(login: "jsmith")
    issue = Issue.generate!(project: @project, status: IssueStatus.find_by!(is_closed: true), due_date: Date.new(2030, 1, 15))
    issue.update_columns(created_on: CREATED, updated_on: UPDATED, closed_on: CLOSED)
    @issue = issue
  end

  teardown do
    switch(off)
  end

  def off = "0"
  def on = "1"

  def switch(value)
    Setting.send(:"plugin_#{RedmineRubylodeHome::PLUGIN_ID}=", RedmineRubylodeHome::Defaults::SETTINGS.merge("dates_without_times" => value))
  end

  def listed_cell(css_class)
    css_select("table.issues td.#{css_class}").first.text.strip
  end

  def list_with_date_columns
    log_user("jsmith", "jsmith")
    get "/projects/#{@project.identifier}/issues", params: { set_filter: 1, status_id: "*", c: %w[subject created_on updated_on closed_on due_date] }
  end

  test "with the setting on, created, updated and closed show the date only, in the person's date format" do
    switch(on)
    list_with_date_columns

    assert_equal format_date(@user.time_to_date(CREATED)), listed_cell("created_on")
    assert_equal format_date(@user.time_to_date(UPDATED)), listed_cell("updated_on")
    assert_equal format_date(@user.time_to_date(CLOSED)), listed_cell("closed_on")
    assert_equal format_date(Date.new(2030, 1, 15)), listed_cell("due_date")
  end

  test "the date follows the person's date format" do
    switch(on)
    with_settings date_format: "%Y-%m-%d" do
      list_with_date_columns
      assert_equal "2014-03-09", listed_cell("created_on")
    end
  end

  test "with the setting off, the columns keep their times" do
    switch(off)
    list_with_date_columns

    assert_equal format_time(CREATED), listed_cell("created_on")
    assert_equal format_time(CLOSED), listed_cell("closed_on")
  end

  test "an upgrade with nothing stored keeps the times" do
    Setting.send(:"plugin_#{RedmineRubylodeHome::PLUGIN_ID}=", {})
    list_with_date_columns

    assert_equal format_time(CREATED), listed_cell("created_on")
  end

  test "an open ticket has an empty closed column with the setting on" do
    switch(on)
    @issue.update_columns(closed_on: nil, status_id: 1)
    list_with_date_columns

    assert_equal "", listed_cell("closed_on")
  end

  test "another list's created column is left alone with the setting on" do
    switch(on)
    entry = TimeEntry.first
    entry.update_columns(created_on: CREATED)
    log_user("admin", "admin")
    get "/time_entries", params: { set_filter: 1, c: %w[spent_on created_on] }

    assert_response :success
    assert_select "table.time-entries td.created_on", text: format_time(CREATED)
  end

  test "the history on the issue page shows the date instead of the age, with the setting on" do
    journal = Journal.create!(journalized: @issue, user: @user, notes: "A comment")
    journal.update_columns(created_on: Time.utc(2020, 5, 5, 14, 30))
    log_user("jsmith", "jsmith")

    switch(on)
    get "/issues/#{@issue.id}"
    assert_response :success
    date = format_date(@user.time_to_date(Time.utc(2020, 5, 5, 14, 30)))
    assert_select "#change-#{journal.id} h4", text: /Updated by John Smith on #{Regexp.escape(date)}/
    assert_select "#change-#{journal.id} h4", text: /ago/, count: 0

    switch(off)
    get "/issues/#{@issue.id}"
    assert_select "#change-#{journal.id} h4", text: /Updated by John Smith .* ago/
  end

  test "the patch is applied to the issue helper once" do
    assert_equal 1, QueriesHelper.ancestors.count { |ancestor| ancestor == RedmineRubylodeHome::DatesWithoutTimes }
  end
end
