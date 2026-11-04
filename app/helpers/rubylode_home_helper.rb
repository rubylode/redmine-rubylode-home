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

# Wording and links for the home page. The data comes from RubylodeHome::HomePage.
module RubylodeHomeHelper
  SOON_DAYS = 13

  def rubylode_home_grouping
    RubylodeHome::IssueGroups::GROUPINGS.include?(params[:group]) ? params[:group] : "project"
  end

  # One HomePage per page drawn, so the tiles and the tickets block on the welcome page read the same lists once.
  def rubylode_home_page
    @rubylode_home_page ||= RubylodeHome::HomePage.new(User.current)
  end

  def rubylode_home_greeting(user)
    zone = user.time_zone || Time.zone
    hour = Time.current.in_time_zone(zone).hour
    part_of_day = if hour < 12 then :morning
                  elsif hour < 18 then :afternoon
                  else :evening
                  end
    l(:"rubylode_home.greeting.#{part_of_day}", name: user.firstname.presence || user.name)
  end

  def rubylode_home_date(date)
    content_tag(:time, "#{day_name(date.wday)}, #{::I18n.l(date, format: :long)}", datetime: date.iso8601)
  end

  def rubylode_home_summary(tiles)
    counts = tiles.to_h { |tile| [tile.key, tile.count] }
    return l(:"rubylode_home.summary.clear") if counts[:assigned_open].zero?

    parts = [l(:"rubylode_home.summary.assigned", count: counts[:assigned_open])]
    parts << l(:"rubylode_home.summary.overdue", count: counts[:overdue]) if counts[:overdue].positive?
    parts << l(:"rubylode_home.summary.this_week", count: counts[:due_this_week]) if counts[:due_this_week].positive?
    parts.to_sentence(locale: current_language) + "."
  end

  # A short, relative due label and the modifier that colours it.
  def rubylode_home_due(issue, rules)
    days = rules.days_until(issue.due_date)
    return if days.nil?

    text, modifier =
      if days.negative? then [l(:"rubylode_home.due.days_overdue", count: -days), "overdue"]
      elsif days.zero? then [l(:"rubylode_home.due.today"), "today"]
      elsif days == 1 then [l(:"rubylode_home.due.tomorrow"), "soon"]
      elsif days <= SOON_DAYS then [l(:"rubylode_home.due.in_days", count: days), "soon"]
      else [l(:"rubylode_home.due.on", date: format_date(issue.due_date)), "later"]
      end
    content_tag(:span, text, class: "rubylode-home-due rubylode-home-due--#{modifier}", title: format_date(issue.due_date))
  end

  def rubylode_home_status_chip(issue)
    tone = if issue.status.is_closed? then "closed"
           elsif issue.tracker&.default_status_id == issue.status_id then "new"
           else "active"
           end
    content_tag(:span, issue.status.name, class: "rubylode-home-chip rubylode-home-chip--status rubylode-home-chip--status-#{tone}",
                                          data: { status_id: issue.status_id })
  end

  # Normal priority says nothing, so only the unusual ones get a chip.
  def rubylode_home_priority_chip(issue)
    priority = issue.priority
    tone = if priority.high? then "high"
           elsif priority.low? then "low"
           end
    return unless tone

    content_tag(:span, priority.name, class: "rubylode-home-chip rubylode-home-chip--priority rubylode-home-chip--priority-#{tone}")
  end

  def rubylode_home_milestone(issue)
    return unless issue.fixed_version

    content_tag(:span, issue.fixed_version.name, class: "rubylode-home-milestone", title: l(:field_fixed_version))
  end

  def rubylode_home_progress(issue)
    return unless issue.done_ratio.to_i.positive?

    content_tag(:span, class: "rubylode-home-progress", title: "#{issue.done_ratio}%",
                       role: "img", aria: { label: l(:"rubylode_home.progress.done", percent: issue.done_ratio) }) do
      content_tag(:span, "", class: "rubylode-home-progress-fill", style: "width: #{issue.done_ratio.to_i}%")
    end
  end

  def rubylode_home_group_title(group)
    if group.project
      link_to(group.project.name, project_issues_path(group.project, set_filter: 1, assigned_to_id: "me", status_id: "o"))
    else
      l(:"rubylode_home.buckets.#{group.key}")
    end
  end

  # A link to the issue list with the filters that match a tile, so the number and the list agree.
  def rubylode_home_tile_path(key, rules)
    filters = { "status_id" => ["o", []] }
    filters["assigned_to_id"] = ["=", ["me"]] unless key == :watched
    case key
    when :due_this_week then filters["due_date"] = ["><", [rules.today.iso8601, rules.week_end.iso8601]]
    when :overdue then filters["due_date"] = ["<=", [(rules.today - 1).iso8601]]
    when :watched then filters["watcher_id"] = ["=", ["me"]]
    end
    issues_path(set_filter: 1, sort: "due_date,priority:desc,id", f: filters.keys + [""],
                op: filters.transform_values(&:first), v: filters.transform_values(&:last).reject { |_field, values| values.empty? })
  end

  def rubylode_home_time_ago(time)
    content_tag(:span, l(:"rubylode_home.ago", time: distance_of_time_in_words(Time.current, time)),
                title: format_time(time), class: "rubylode-home-time-ago")
  end
end
