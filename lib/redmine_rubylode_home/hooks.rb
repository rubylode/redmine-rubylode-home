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
  # The My page itself is replaced by the plugin's view (app/views/my/page.html.erb). These hooks load the stylesheet
  # where the plugin draws something, and put the four tiles on the welcome page for a signed-in person.
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_welcome_index_left, partial: "rubylode_home/welcome"

    def view_layouts_base_html_head(context)
      return unless my_page?(context) || signed_in_welcome_page?(context)

      stylesheet_link_tag("rubylode_home", plugin: "redmine_rubylode_home")
    end

    private

    def my_page?(context)
      controller = context[:controller]
      controller.is_a?(MyController) && controller.action_name == "page"
    end

    def signed_in_welcome_page?(context)
      context[:controller].is_a?(WelcomeController) && User.current.logged?
    end
  end
end
