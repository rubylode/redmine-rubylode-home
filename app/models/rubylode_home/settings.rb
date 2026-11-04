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
  # The plugin's settings, read with the defaults filled in. A stored value that is not one of the choices counts as
  # the default, so a hand-edited setting cannot break a page.
  class Settings
    PLUGIN_ID = :redmine_rubylode_home
    WELCOME_PAGE_CONTENTS = %w[tiles tickets].freeze
    COLUMNS = %w[left right].freeze

    # What a fresh install, and an upgrade from 1.0.0, starts with. The defaults keep the plugin's earlier behavior.
    DEFAULTS = {
      "welcome_page_content" => "tiles",
      "welcome_page_column" => "right",
      "dates_without_times" => "0"
    }.freeze

    def self.current
      new(Setting.send(:"plugin_#{PLUGIN_ID}"))
    end

    def initialize(stored_settings)
      @settings = DEFAULTS.merge((stored_settings || {}).to_h.stringify_keys.compact)
    end

    def welcome_page_content
      choice("welcome_page_content", WELCOME_PAGE_CONTENTS)
    end

    def welcome_page_tickets?
      welcome_page_content == "tickets"
    end

    def welcome_page_column
      choice("welcome_page_column", COLUMNS)
    end

    def dates_without_times?
      @settings["dates_without_times"].to_s == "1"
    end

    private

    def choice(key, allowed)
      allowed.include?(@settings[key].to_s) ? @settings[key].to_s : DEFAULTS[key]
    end
  end
end
