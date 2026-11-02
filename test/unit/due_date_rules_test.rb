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

class DueDateRulesTest < ActiveSupport::TestCase
  WEDNESDAY = Date.new(2026, 10, 28)
  MONDAY = 1
  SUNDAY = 7
  SATURDAY = 6

  def rules(today: WEDNESDAY, first_day_of_week: MONDAY)
    RubylodeHome::DueDateRules.new(today: today, first_day_of_week: first_day_of_week)
  end

  test "a week that starts on Monday ends on the Sunday after today" do
    assert_equal Date.new(2026, 11, 1), rules.week_end
  end

  test "a week that starts on Sunday ends on the Saturday after today" do
    assert_equal Date.new(2026, 10, 31), rules(first_day_of_week: SUNDAY).week_end
  end

  test "a week that starts on Saturday ends on Friday" do
    assert_equal Date.new(2026, 10, 30), rules(first_day_of_week: SATURDAY).week_end
  end

  test "on the last day of the week the week ends today" do
    sunday = Date.new(2026, 11, 1)
    assert_equal sunday, rules(today: sunday).week_end
  end

  test "a first day of week of zero means Sunday, as Ruby counts it" do
    assert_equal Date.new(2026, 10, 31), rules(first_day_of_week: 0).week_end
  end

  test "a due date before today is overdue and today is not" do
    assert rules.overdue?(WEDNESDAY - 1)
    assert_not rules.overdue?(WEDNESDAY)
    assert_not rules.overdue?(nil)
  end

  test "due this week runs from today to the end of the week, overdue dates excluded" do
    assert rules.due_this_week?(WEDNESDAY)
    assert rules.due_this_week?(Date.new(2026, 11, 1))
    assert_not rules.due_this_week?(Date.new(2026, 11, 2))
    assert_not rules.due_this_week?(WEDNESDAY - 1)
    assert_not rules.due_this_week?(nil)
  end

  test "each due date falls in exactly one bucket" do
    assert_equal :overdue, rules.bucket_for(WEDNESDAY - 3)
    assert_equal :today, rules.bucket_for(WEDNESDAY)
    assert_equal :this_week, rules.bucket_for(WEDNESDAY + 1)
    assert_equal :next_week, rules.bucket_for(Date.new(2026, 11, 2))
    assert_equal :next_week, rules.bucket_for(Date.new(2026, 11, 8))
    assert_equal :later, rules.bucket_for(Date.new(2026, 11, 9))
    assert_equal :no_due_date, rules.bucket_for(nil)
  end

  test "the buckets come in the order a person works through them" do
    assert_equal %i[overdue today this_week next_week later no_due_date], RubylodeHome::DueDateRules::BUCKETS
  end

  test "due soon covers overdue dates and the next fourteen days" do
    assert rules.due_soon?(WEDNESDAY - 30)
    assert rules.due_soon?(WEDNESDAY + 13)
    assert_not rules.due_soon?(WEDNESDAY + 14)
    assert_not rules.due_soon?(nil)
    assert_equal WEDNESDAY + 13, rules.due_soon_end
  end

  test "days until due counts negative for overdue dates" do
    assert_equal(-2, rules.days_until(WEDNESDAY - 2))
    assert_equal 0, rules.days_until(WEDNESDAY)
    assert_equal 5, rules.days_until(WEDNESDAY + 5)
    assert_nil rules.days_until(nil)
  end
end
