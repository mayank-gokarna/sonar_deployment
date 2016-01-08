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
module ComponentsHelper
  include ActionView::Helpers::UrlHelper

  def get_header_content(column, snapshot)
    get_column_content(column, snapshot, {snapshot => snapshot.measures}, 'th')
  end

  def get_column_content(column, snapshot, measures_by_snapshot, html_node='td')
    project = snapshot.project
    content = ''
    nowrap = true
    measure_param = '0'

    if column.language_column?
      content = project.language || ''

    elsif column.version_column?
      content = snapshot.version || ''

    elsif column.links_column?
      links = links_by_project_id[project.id]
      if links
        links.each do |link|
          content << link_to(image_tag(link.icon, :alt => link.name), link.href, :class => 'nolink', :popup => true) unless link.custom?
        end
      end
    elsif column.build_time_column?
      measure_param = snapshot.created_at.tv_sec
      content = human_short_date( snapshot.created_at )

    elsif column.metric_column?
      measure = item_by_metric_id(measures_by_snapshot[snapshot], column.id )
      measure_param = measure.value if measure
      content = format_measure(measure) + trend_icon(measure, :empty => true)
    end

    "<#{html_node} #{"nowrap='nowrap'" if nowrap} #{"x='#{measure_param}'" if measure_param} class='right'>" + content + "</#{html_node}>"
  end


  def search_measure(measures, metric_key)
    item_by_metric_id(measures, metric_key )
  end

  private

  def item_by_metric_id(items, metric_name)
    return nil if items.nil?
    items.each do |item|
      metric = Metric.by_name(metric_name)
      return item if (item && metric && item.metric_id==metric.id && item.rule_priority.nil? && item.characteristic_id.nil? && item.person_id.nil?)
    end
    nil
  end

  def links_by_project_id
    @links_by_project_id ||= {}
    if @links_by_project_id.empty?
      ProjectLink.find(:all, :order => 'link_type').each do |link|
        @links_by_project_id[link.project_id] ||= []
        @links_by_project_id[link.project_id]<<link
      end
    end
    @links_by_project_id
  end

end
