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
class AddMeasureData < ActiveRecord::Migration

  def self.up
    create_table :measure_data do |t|
      t.column :measure_id, :integer, :null => true
      t.column :snapshot_id, :integer, :null => true
      t.column :data, :binary, :null => true
    end
    add_index :measure_data, :measure_id, :name => 'measure_data_measure_id'   
  end

end