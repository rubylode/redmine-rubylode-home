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

# The page's data for one person. dlopper is a member of the public project 1 only; project 2 is private and he is not in it.
class RubylodeHomePageTest < ActiveSupport::TestCase
  fixtures :projects, :users, :email_addresses, :roles, :members, :member_roles, :enabled_modules, :issues, :issue_statuses,
           :trackers, :projects_trackers, :enumerations, :workflows, :journals, :journal_details, :watchers, :groups_users

  WEDNESDAY = Date.new(2026, 10, 28)

  def setup
    @person = User.find(3)
    Issue.update_all(assigned_to_id: nil)
    Watcher.delete_all
    Journal.where(user_id: @person.id).delete_all
    Issue.where(author_id: @person.id).update_all(author_id: 2)
  end

  def home_page(user = @person)
    RubylodeHome::HomePage.new(user, today: WEDNESDAY, first_day_of_week: 1)
  end

  def assigned_issue(due: nil, project_id: 1, status_id: 1, assignee: @person, **attributes)
    issue = Issue.generate!(project_id: project_id, due_date: due, start_date: nil, **attributes)
    issue.update_columns(assigned_to_id: assignee.id, status_id: status_id)
    issue
  end

  test "the counts cover open tickets assigned to the person, due this week, overdue and watched" do
    assigned_issue(due: WEDNESDAY - 2)
    assigned_issue(due: WEDNESDAY)
    assigned_issue(due: WEDNESDAY + 4)
    assigned_issue(due: WEDNESDAY + 10)
    assigned_issue
    assigned_issue(due: WEDNESDAY - 5, status_id: 5) # closed
    Issue.find(1).add_watcher(@person)
    Issue.find(3).add_watcher(@person)

    counts = home_page.tiles.to_h { |tile| [tile.key, tile.count] }
    assert_equal({ assigned_open: 5, due_this_week: 2, overdue: 1, watched: 2 }, counts)
  end

  test "tickets in a project the person cannot see are left out of every list and count" do
    hidden = assigned_issue(due: WEDNESDAY - 1, project_id: 2)
    Issue.find(4).add_watcher(@person) # project 2
    visible = assigned_issue(due: WEDNESDAY - 1)

    page = home_page
    assert_equal [visible.id], page.assigned_issues.map(&:id)
    assert_equal [visible.id], page.due_soon_issues.map(&:id)
    assert_not_includes page.watched_issues.map(&:id), 4
    counts = page.tiles.to_h { |tile| [tile.key, tile.count] }
    assert_equal({ assigned_open: 1, due_this_week: 0, overdue: 1, watched: 0 }, counts)
    assert_not_includes page.recently_updated_issues.map(&:id), hidden.id
  end

  test "a ticket assigned to one of the person's groups counts as assigned to them" do
    group = Group.find(10)
    group.users << @person unless group.users.include?(@person)
    with_settings issue_group_assignment: "1" do
      issue = assigned_issue(assignee: group)
      assert_includes home_page.assigned_issues.map(&:id), issue.id
    end
  end

  test "due soon lists overdue tickets and those due in the next two weeks, earliest first" do
    later = assigned_issue(due: WEDNESDAY + 20)
    soon = assigned_issue(due: WEDNESDAY + 3)
    overdue = assigned_issue(due: WEDNESDAY - 3)
    undated = assigned_issue

    ids = home_page.due_soon_issues.map(&:id)
    assert_equal [overdue.id, soon.id], ids
    assert_not_includes ids, later.id
    assert_not_includes ids, undated.id
  end

  test "recently updated lists tickets the person wrote, commented on or is assigned to, newest first" do
    written = Issue.generate!(author: @person)
    written.update_columns(updated_on: 3.days.ago)
    commented = Issue.find(2)
    commented.update_columns(updated_on: 1.day.ago)
    Journal.create!(journalized: commented, user: @person, notes: "Looked at it")
    assigned = assigned_issue
    assigned.update_columns(updated_on: 2.days.ago)
    untouched = Issue.generate!
    untouched.update_columns(updated_on: 1.hour.ago)

    ids = home_page.recently_updated_issues.map(&:id)
    assert_equal [commented.id, assigned.id, written.id], ids
  end

  test "watched lists open watched tickets only" do
    Issue.find(1).add_watcher(@person)
    closed = Issue.find(8) # closed in the fixtures
    closed.add_watcher(@person)
    assert_equal [1], home_page.watched_issues.map(&:id)
  end

  test "the assigned list stops at its limit while the count stays true" do
    (RubylodeHome::HomePage::ASSIGNED_LIMIT + 2).times { assigned_issue }
    page = home_page
    assert_equal RubylodeHome::HomePage::ASSIGNED_LIMIT, page.assigned_issues.size
    assert_equal RubylodeHome::HomePage::ASSIGNED_LIMIT + 2, page.tiles.first.count
    assert page.more_assigned_issues?
  end

  test "the assigned groups follow the chosen grouping" do
    assigned_issue(due: WEDNESDAY - 1)
    assigned_issue
    assert_equal %i[overdue no_due_date], home_page.assigned_groups("due_date").map(&:key)
    assert_equal [1], home_page.assigned_groups("project").map(&:key)
  end

  test "a person who may add tickets somewhere gets the new issue entry, an anonymous visitor does not" do
    assert home_page.can_add_issues?
    assert_not home_page(User.anonymous).can_add_issues?
  end

  test "the first day of the week follows Redmine's setting" do
    with_settings start_of_week: "7" do
      assert_equal 7, RubylodeHome::HomePage.first_day_of_week
    end
    with_settings start_of_week: "6" do
      assert_equal 6, RubylodeHome::HomePage.first_day_of_week
    end
  end
end
