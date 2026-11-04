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
  # Everything the home page shows for one person, read once per request. Every list goes through Issue.visible,
  # so a ticket the person cannot open never shows, and every list loads the records its rows need in one go.
  class HomePage
    ASSIGNED_LIMIT = 30
    CARD_LIMIT = 8
    ACTIVITY_LIMIT = 8
    ACTIVITY_DAYS = 30
    ROW_ASSOCIATIONS = %i[project status priority tracker assigned_to fixed_version].freeze

    attr_reader :user, :rules

    # Redmine's week setting: blank means the language's own first day; "1" Monday, "6" Saturday, "7" Sunday.
    def self.first_day_of_week
      setting = Setting.start_of_week.presence || I18n.t(:general_first_day_of_week, default: "1")
      setting.to_i
    end

    def initialize(user, today: user.today, first_day_of_week: self.class.first_day_of_week)
      @user = user
      @rules = DueDateRules.new(today: today, first_day_of_week: first_day_of_week)
    end

    def today = rules.today

    def assigned_issues
      @assigned_issues ||= rows(open_assigned_scope).limit(ASSIGNED_LIMIT).to_a
    end

    def more_assigned_issues?
      assigned_open_count > assigned_issues.size
    end

    def assigned_groups(grouping)
      IssueGroups.new(assigned_issues, rules).group_by(grouping)
    end

    def due_soon_issues
      @due_soon_issues ||= rows(open_assigned_scope.where(issues: { due_date: ..rules.due_soon_end }))
                           .reorder(:due_date, :id).limit(CARD_LIMIT).to_a
    end

    def recently_updated_issues
      @recently_updated_issues ||= rows(visible_issues.where(touched_condition, user_id: user.id, assignee_ids: assignee_ids))
                                   .reorder(updated_on: :desc, id: :desc).limit(CARD_LIMIT).to_a
    end

    def watched_issues
      @watched_issues ||= rows(open_watched_scope).reorder(updated_on: :desc, id: :desc).limit(CARD_LIMIT).to_a
    end

    def tiles
      @tiles ||= SummaryTiles.new(
        assigned_open: assigned_open_count,
        due_this_week: open_assigned_scope.where(issues: { due_date: rules.today..rules.week_end }).count,
        overdue: open_assigned_scope.where(issues: { due_date: ...rules.today }).count,
        watched: open_watched_scope.count
      ).tiles
    end

    def recent_events
      @recent_events ||= begin
        fetcher = Redmine::Activity::Fetcher.new(user)
        fetcher.scope = :default
        fetcher.events(today - ACTIVITY_DAYS, today + 1, limit: ACTIVITY_LIMIT)
      end
    end

    def can_add_issues?
      user.logged? && user.allowed_to?(:add_issues, nil, global: true)
    end

    private

    def assigned_open_count
      @assigned_open_count ||= open_assigned_scope.count
    end

    def visible_issues
      Issue.visible(user)
    end

    def open_assigned_scope
      visible_issues.open.where(assigned_to_id: assignee_ids)
    end

    def open_watched_scope
      visible_issues.open.watched_by(user)
    end

    # The person and the groups they belong to, the same as Redmine's "assigned to me" filter.
    def assignee_ids
      @assignee_ids ||= [user.id] + user.group_ids
    end

    def touched_condition
      <<~SQL.squish
        issues.author_id = :user_id OR issues.assigned_to_id IN (:assignee_ids) OR issues.id IN (
          SELECT journals.journalized_id FROM journals
          WHERE journals.journalized_type = 'Issue' AND journals.user_id = :user_id)
      SQL
    end

    # Undated tickets last, then by due date, so a list cut at its limit keeps the most pressing ones.
    def rows(scope)
      scope.preload(*ROW_ASSOCIATIONS)
           .reorder(Arel.sql("CASE WHEN issues.due_date IS NULL THEN 1 ELSE 0 END"), :due_date, :id)
    end
  end
end
