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
# Sonar 2.10
#
class DropAsyncMeasuresTable < ActiveRecord::Migration

  def self.up
    remove_index('async_measure_snapshots', :name => 'async_m_s_snapshot_id')
    remove_index('async_measure_snapshots', :name => 'async_m_s_measure_id')
    remove_index('async_measure_snapshots', :name => 'async_m_s_project_metric')
    drop_table('async_measure_snapshots')
  end
  
end
