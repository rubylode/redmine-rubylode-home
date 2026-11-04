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

require "redmine"

Redmine::Plugin.register :redmine_rubylode_home do
  name "Rubylode Home"
  author "Rubylode"
  author_url "https://github.com/rubylode"
  url "https://github.com/rubylode/redmine-rubylode-home"
  description "A home view for Redmine's My page: your tickets, due dates and watched tickets on one page"
  version "2.0.0"
  requires_redmine version_or_higher: "5.1.0"

  settings default: RubylodeHome::Settings::DEFAULTS, partial: "settings/rubylode_home"
end

require_relative "lib/rubylode_home/hooks"
require_relative "lib/rubylode_home/settings_controller_patch"
require_relative "lib/rubylode_home/dates_without_times"

# Redmine renders only a controller's own helpers, so the two pages the plugin draws on get the plugin's helper too.
# This file runs on every code reload, and adding the same helper twice is harmless.
MyController.helper(RubylodeHomeHelper)
WelcomeController.helper(RubylodeHomeHelper)

# Plugins load after the boot-time prepare callbacks have run, so apply the patch now and again after each code reload.
apply_settings_controller_patch = lambda do
  unless SettingsController.include?(RubylodeHome::SettingsControllerPatch)
    SettingsController.prepend RubylodeHome::SettingsControllerPatch
  end
end
apply_settings_controller_patch.call
Rails.configuration.to_prepare(&apply_settings_controller_patch)

# The same for the dates patch: applied once now and again after each reload, never twice.
apply_dates_without_times = lambda do
  QueriesHelper.prepend RubylodeHome::DatesWithoutTimes unless QueriesHelper.include?(RubylodeHome::DatesWithoutTimes)
end
apply_dates_without_times.call
Rails.configuration.to_prepare(&apply_dates_without_times)
