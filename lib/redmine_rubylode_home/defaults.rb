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

module RedmineRubylodeHome
  PLUGIN_ID = :redmine_rubylode_home

  # What a fresh install, and an upgrade from 1.0.0, starts with. The defaults keep the plugin's earlier behaviour.
  module Defaults
    SETTINGS = {
      "welcome_page_content" => "tiles",
      "welcome_page_column" => "right",
      "dates_without_times" => "0"
    }.freeze
  end
end
