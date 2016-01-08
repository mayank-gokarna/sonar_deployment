#
# SonarQube, open source software quality management tool.
# Copyright (C) 2008-2013 SonarSource
# mailto:contact AT sonarsource DOT com
#
# SonarQube is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 3 of the License, or (at your option) any later version.
#
# SonarQube is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

#
# Sonar 2.3
#
class DeleteCheckstyleTranslations < ActiveRecord::Migration

  class Rule < ActiveRecord::Base
  end

  class ActiveRule < ActiveRecord::Base
  end

  def self.up
    Rule.reset_column_information
    ActiveRule.reset_column_information
    delete_rule('com.puppycrawl.tools.checkstyle.checks.TranslationCheck')
  end

  private
  def self.delete_rule(rule_key)
    rule=Rule.find(:first, :conditions => {:plugin_name => 'checkstyle', :plugin_rule_key => rule_key})
    if rule
      say_with_time "Delete Checkstyle rule #{rule_key}..." do
        rule_id=rule.id
        ActiveRule.destroy_all(["rule_id=?", rule_id])
        rule.destroy
      end
    end
  end
end
