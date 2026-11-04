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
  # Checks the settings form before it is saved. Returns a list of messages, empty when everything is fine.
  # A key that is not in the form is not checked, so a partial post cannot fail on what it does not mention.
  class SettingsValidator
    CHOICES = {
      "welcome_page_content" => Settings::WELCOME_PAGE_CONTENTS,
      "welcome_page_column" => Settings::COLUMNS,
      "dates_without_times" => %w[0 1]
    }.freeze

    def self.errors_for(raw_settings)
      new(raw_settings).errors
    end

    def initialize(raw_settings)
      @settings = (raw_settings || {}).to_h.stringify_keys
    end

    def errors
      CHOICES.filter_map do |key, allowed|
        next if !@settings.key?(key) || allowed.include?(@settings[key].to_s)

        I18n.t("rubylode_home.errors.#{key}_invalid", choices: allowed.join(", "))
      end
    end
  end
end
