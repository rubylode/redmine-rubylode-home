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

# Demo data for trying the home view: six people, six projects and about 300 tickets with due dates around today,
# watchers and recent comments. Everything is made up. Only for the throwaway Redmine in docker-compose.yml.
#
#   ruby bin/demo up        (runs this script)
#   docker compose exec redmine bin/rails runner plugins/redmine_rubylode_home/script/seed_demo.rb
#
# Safe to run twice: people, the role and the projects are found or created, and a project that already has tickets is
# left as it is. Every person signs in with their login and the password below; the administrator is admin / admin.

DEMO_PASSWORD = "demo-password-1".freeze
REVIEWER_LOGIN = "sam.rivera".freeze
TICKETS_PER_PROJECT = 50
CLOSED_SHARE = 0.35
DAYS_OF_HISTORY = 60

DEMO_USERS = [
  { login: REVIEWER_LOGIN, firstname: "Sam", lastname: "Rivera" },
  { login: "jordan.lee", firstname: "Jordan", lastname: "Lee" },
  { login: "priya.shah", firstname: "Priya", lastname: "Shah" },
  { login: "marco.bianchi", firstname: "Marco", lastname: "Bianchi" },
  { login: "emma.novak", firstname: "Emma", lastname: "Novak" },
  { login: "li.wei", firstname: "Li", lastname: "Wei" }
].freeze

DEMO_PROJECTS = [
  { name: "Website Refresh", identifier: "website-refresh",
    actions: ["Redesign", "Write copy for", "Fix layout of", "Test", "Speed up", "Review"],
    things: ["the pricing page", "the signup form", "the blog index", "the footer links", "the search results", "the contact page",
             "the image gallery", "the cookie banner"] },
  { name: "Mobile App", identifier: "mobile-app",
    actions: ["Fix crash in", "Add dark mode to", "Polish", "Translate", "Profile", "Ship"],
    things: ["the login screen", "push notifications", "the settings screen", "offline sync", "the onboarding flow", "the map view",
             "in-app purchases", "the share sheet"] },
  { name: "Customer Support", identifier: "customer-support",
    actions: ["Answer", "Write a help article on", "Escalate", "Follow up on", "Close out", "Triage"],
    things: ["refund requests", "password resets", "invoice questions", "the shipping delay", "account merges", "the export bug report",
             "billing address changes", "the onboarding call"] },
  { name: "Data Platform", identifier: "data-platform",
    actions: ["Migrate", "Back up", "Monitor", "Clean up", "Document", "Index"],
    things: ["the orders table", "nightly exports", "the reporting views", "old event logs", "the warehouse schema", "slow dashboards",
             "the customer dimension", "the archive bucket"] },
  { name: "Office Move", identifier: "office-move",
    actions: ["Order", "Book", "Label", "Set up", "Measure", "Plan"],
    things: ["desks for the new floor", "the moving van", "network cabling", "the meeting rooms", "the kitchen", "parking passes",
             "the printer corner", "the storage room"] },
  { name: "Marketing Launch", identifier: "marketing-launch",
    actions: ["Draft", "Schedule", "Proofread", "Design", "Approve", "Plan"],
    things: ["the launch email", "social posts", "the press kit", "the landing page banner", "the webinar", "partner announcements",
             "the product video", "the newsletter"] }
].freeze

COMMENTS = [
  "Looked into this, it needs another pass.",
  "Moved it forward, see the latest changes.",
  "Waiting on a reply before I go on.",
  "Done on my side, please check.",
  "Picked this up today.",
  "Found the cause, fixing it next.",
  "Can we talk about this at the next meeting?",
  "Updated the description with the steps."
].freeze

def random_generator
  @random_generator ||= Random.new(2026)
end

def pick(list)
  list[random_generator.rand(list.size)]
end

def chance(probability)
  random_generator.rand < probability
end

def ensure_default_data
  return if Tracker.exists? && IssueStatus.exists? && IssuePriority.exists?

  Redmine::DefaultData::Loader.load("en")
  puts "Loaded Redmine's default trackers, statuses, priorities and roles."
end

def ensure_settings
  Setting.default_language = "en"
  Setting.notified_events = []
end

# Preview only: the throwaway Redmine asks for a new administrator password on first sign-in. The short password skips
# Redmine's length rule on purpose; never run this against a real tracker.
def ensure_preview_admin
  admin = User.find_by!(login: "admin")
  admin.password = admin.password_confirmation = "admin"
  admin.must_change_passwd = false
  admin.save!(validate: false)
end

def ensure_role
  role = Role.find_or_initialize_by(name: "Demo member")
  role.assignable = true
  role.issues_visibility = "all"
  role.permissions = %i[view_issues add_issues edit_issues add_issue_notes view_issue_watchers add_issue_watchers
                        delete_issue_watchers manage_subtasks]
  role.save!
  role
end

def ensure_users
  DEMO_USERS.map do |attributes|
    user = User.find_or_initialize_by(login: attributes[:login])
    user.firstname = attributes[:firstname]
    user.lastname = attributes[:lastname]
    user.mail = "#{attributes[:login]}@example.com"
    if user.new_record?
      user.password = user.password_confirmation = DEMO_PASSWORD
      user.must_change_passwd = false
      user.language = "en"
    end
    user.save!
    user
  end
end

def ensure_project(definition, users, role)
  project = Project.find_or_initialize_by(identifier: definition[:identifier])
  project.name = definition[:name]
  project.is_public = false
  project.trackers = Tracker.all
  project.enabled_module_names = (Setting.default_projects_modules + %w[issue_tracking]).uniq
  project.save!
  users.each do |user|
    Member.create!(project: project, user: user, roles: [role]) unless project.members.exists?(user_id: user.id)
  end
  project
end

# Open tickets get due dates around today so every tile and bucket has something in it.
def due_date_for_open_ticket(today)
  week_end = RubylodeHome::DueDateRules.new(today: today, first_day_of_week: RubylodeHome::HomePage.first_day_of_week).week_end
  roll = random_generator.rand
  if roll < 0.14 then today - random_generator.rand(1..20)
  elsif roll < 0.24 then today + random_generator.rand(0..(week_end - today).to_i)
  elsif roll < 0.30 then today + random_generator.rand(0..6)
  elsif roll < 0.55 then today + random_generator.rand(7..40)
  end
end

def assignee_for(users, reviewer)
  return nil if chance(0.08)

  chance(0.15) ? reviewer : pick(users)
end

def add_comment(issue, user, time, status: nil, done_ratio: nil)
  issue.reload
  issue.init_journal(user, pick(COMMENTS))
  issue.status = status if status
  issue.done_ratio = done_ratio if done_ratio
  issue.save!
  issue.journals.order(:id).last.update_columns(created_on: time)
end

def seed_tickets(project, definition, users, reviewer, now)
  today = now.to_date
  trackers = Tracker.sorted.to_a
  priorities = IssuePriority.active.to_a
  weighted_priorities = priorities + priorities.select { |priority| priority.name == "Normal" } * 4
  statuses = IssueStatus.all.index_by(&:name)
  open_statuses = [statuses["New"], statuses["New"], statuses["In Progress"], statuses["In Progress"], statuses["Feedback"],
                   statuses["Resolved"]].compact
  closed_statuses = [statuses["Closed"], statuses["Closed"], statuses["Closed"], statuses["Rejected"]].compact

  TICKETS_PER_PROJECT.times do
    closed = chance(CLOSED_SHARE)
    created_at = now - random_generator.rand(1..DAYS_OF_HISTORY).days - random_generator.rand(0..8).hours
    author = pick(users)
    issue = Issue.new(
      project: project, tracker: pick(trackers), author: author, priority: pick(weighted_priorities),
      subject: "#{pick(definition[:actions])} #{pick(definition[:things])}",
      assigned_to: assignee_for(users, reviewer), status: statuses["New"],
      start_date: nil, due_date: (closed ? created_at.to_date + random_generator.rand(3..20) : due_date_for_open_ticket(today))
    )
    issue.save!
    # A query on the row: update_columns on the object that was just saved changes nothing.
    Issue.where(id: issue.id).update_all(created_on: created_at, updated_on: created_at)

    watchers = (users - [reviewer]).sample(random_generator.rand(0..2), random: random_generator)
    watchers << reviewer if chance(0.07)

    final_status = closed ? pick(closed_statuses) : pick(open_statuses)
    unless final_status == statuses["New"] && chance(0.6)
      commenter = issue.assigned_to.is_a?(User) ? issue.assigned_to : pick(users)
      commenter = reviewer if chance(0.15)
      comment_time = [created_at + random_generator.rand(1..10).days, now - random_generator.rand(1..72).hours].min
      done_ratio = closed ? 100 : [0, 10, 20, 40, 60, 80].sample(random: random_generator)
      add_comment(issue, commenter, comment_time, status: final_status, done_ratio: done_ratio)
      Issue.where(id: issue.id).update_all(updated_on: comment_time, closed_on: (closed ? comment_time : nil))
    end

    set_watchers(issue, watchers.uniq)
  end
end

# Redmine makes authors and commenters watchers on its own; the demo picks its watchers instead, so the counts stay readable.
def set_watchers(issue, users)
  issue.watchers.delete_all
  users.each { |user| Watcher.create!(watchable: issue, user: user) }
end

User.current = User.find_by!(login: "admin")
now = Time.current
Mailer.with_deliveries(false) do
  ensure_default_data
  ensure_settings
  ensure_preview_admin
  role = ensure_role
  users = ensure_users
  reviewer = users.find { |user| user.login == REVIEWER_LOGIN }
  DEMO_PROJECTS.each do |definition|
    project = ensure_project(definition, users, role)
    if project.issues.exists?
      puts "#{project.name}: already has tickets, left as it is."
    else
      seed_tickets(project, definition, users, reviewer, now)
    end
  end
end

reviewer = User.find_by!(login: REVIEWER_LOGIN)
home = RubylodeHome::HomePage.new(reviewer)
projects = Project.where(identifier: DEMO_PROJECTS.map { |definition| definition[:identifier] })
puts "Projects: #{projects.map(&:name).join(', ')}"
puts "Tickets: #{Issue.where(project: projects).count} (#{Issue.where(project: projects).open.count} open), " \
     "comments: #{Journal.where(journalized_type: 'Issue', journalized_id: Issue.where(project: projects).select(:id)).count}, " \
     "watchers: #{Watcher.where(watchable_type: 'Issue').count}"
puts "People: #{DEMO_USERS.map { |attributes| attributes[:login] }.join(', ')} (password #{DEMO_PASSWORD})"
puts "#{REVIEWER_LOGIN}'s tiles: #{home.tiles.map { |tile| "#{tile.key} #{tile.count}" }.join(', ')}"
