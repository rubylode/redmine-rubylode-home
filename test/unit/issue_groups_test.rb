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

require File.expand_path("../test_helper", __dir__)

# The grouping works on anything that answers like an issue, so these tests use small stand-ins and no database.
class IssueGroupsTest < ActiveSupport::TestCase
  WEDNESDAY = Date.new(2026, 10, 28)
  FakeProject = Struct.new(:id, :name)
  FakePriority = Struct.new(:position)
  FakeIssue = Struct.new(:id, :project, :due_date, :priority)

  GARDEN = FakeProject.new(1, "Garden")
  ATTIC = FakeProject.new(2, "attic")
  LOW = FakePriority.new(1)
  HIGH = FakePriority.new(3)

  def rules
    RubylodeHome::DueDateRules.new(today: WEDNESDAY, first_day_of_week: 1)
  end

  def issue(id, project: GARDEN, due: nil, priority: LOW)
    FakeIssue.new(id, project, due, priority)
  end

  test "by project, projects sort by name without regard to case" do
    groups = RubylodeHome::IssueGroups.new([issue(1, project: GARDEN), issue(2, project: ATTIC)], rules).by_project
    assert_equal %w[attic Garden], groups.map { |group| group.project.name }
    assert_equal [ATTIC.id, GARDEN.id], groups.map(&:key)
  end

  test "inside a group the earliest due date comes first, undated last, then the higher priority, then the older ticket" do
    issues = [
      issue(1),
      issue(2, due: WEDNESDAY + 5),
      issue(3, due: WEDNESDAY - 2),
      issue(4, due: WEDNESDAY + 5, priority: HIGH),
      issue(5, priority: HIGH)
    ]
    group = RubylodeHome::IssueGroups.new(issues, rules).by_project.first
    assert_equal [3, 4, 2, 5, 1], group.issues.map(&:id)
  end

  test "by due date, the buckets keep their working order and empty buckets are left out" do
    issues = [issue(1), issue(2, due: WEDNESDAY - 1), issue(3, due: WEDNESDAY + 40), issue(4, due: WEDNESDAY)]
    groups = RubylodeHome::IssueGroups.new(issues, rules).by_due_date
    assert_equal %i[overdue today later no_due_date], groups.map(&:key)
    assert_equal [[2], [4], [3], [1]], groups.map { |group| group.issues.map(&:id) }
    assert_nil groups.first.project
  end

  test "group_by picks the grouping by name and falls back to project for anything unknown" do
    groups = RubylodeHome::IssueGroups.new([issue(1, due: WEDNESDAY)], rules)
    assert_equal [:today], groups.group_by("due_date").map(&:key)
    assert_equal [GARDEN.id], groups.group_by("project").map(&:key)
    assert_equal [GARDEN.id], groups.group_by("something else").map(&:key)
  end

  test "no issues make no groups" do
    assert_empty RubylodeHome::IssueGroups.new([], rules).by_project
    assert_empty RubylodeHome::IssueGroups.new([], rules).by_due_date
  end

  test "the issue count of a group is its size" do
    group = RubylodeHome::IssueGroups.new([issue(1), issue(2)], rules).by_project.first
    assert_equal 2, group.size
  end
end
