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
# Sonar 2.13
#
class CreateLoadedTemplates < ActiveRecord::Migration

  class Dashboard < ActiveRecord::Base
  end

  class LoadedTemplate < ActiveRecord::Base
  end

  def self.up
    create_table 'loaded_templates' do |t|
      t.column 'kee', :string, :null => true, :limit => 200
      t.column 'template_type', :string, :null => true, :limit => 15
    end

    # if this is a migration, then the default dashboard already exists in the DB so it should not be loaded again
    Dashboard.reset_column_information
    if Dashboard.exists?(:name => 'Dashboard', :user_id => nil)
      LoadedTemplate.reset_column_information
      LoadedTemplate.create({:template_type => 'DASHBOARD', :kee => 'Dashboard'})
    end
  end

end
