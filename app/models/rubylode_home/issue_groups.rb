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

module RubylodeHome
  # Splits a list of tickets into groups, by project or by when they are due. Works on anything that answers
  # id, project, due_date and priority.position, so it needs no database of its own.
  class IssueGroups
    GROUPINGS = %w[project due_date].freeze

    Group = Struct.new(:key, :project, :issues) do
      def size = issues.size
    end

    def initialize(issues, rules)
      @issues = issues.to_a
      @rules = rules
    end

    def group_by(grouping)
      grouping.to_s == "due_date" ? by_due_date : by_project
    end

    def by_project
      @issues.group_by(&:project)
             .sort_by { |project, _issues| [project.name.to_s.downcase, project.id] }
             .map { |project, issues| Group.new(project.id, project, in_working_order(issues)) }
    end

    def by_due_date
      buckets = @issues.group_by { |issue| @rules.bucket_for(issue.due_date) }
      DueDateRules::BUCKETS.filter_map do |bucket|
        Group.new(bucket, nil, in_working_order(buckets[bucket])) if buckets[bucket]
      end
    end

    private

    # Earliest due date first, undated last; then the higher priority; then the older ticket.
    def in_working_order(issues)
      issues.sort_by do |issue|
        [issue.due_date ? 0 : 1, issue.due_date || Date.new(0), -issue.priority.position.to_i, issue.id]
      end
    end
  end
end
