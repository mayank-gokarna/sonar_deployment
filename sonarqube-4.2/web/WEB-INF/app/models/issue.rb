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

class Issue

  def self.to_hash(issue, rule_name=nil)
    hash = {
        :key => issue.key,
        :component => issue.componentKey,
        :componentId => issue.componentId,
        :project => issue.projectKey,
        :rule => issue.ruleKey.toString(),
        :status => issue.status
    }
    hash[:resolution] = issue.resolution if issue.resolution
    hash[:severity] = issue.severity if issue.severity
    hash[:message] = issue.message if issue.message
    hash[:line] = issue.line.to_i if issue.line
    hash[:effortToFix] = issue.effortToFix.to_f if issue.effortToFix
    hash[:technicalDebt] = technical_debt_to_hash(issue.technicalDebt) if issue.technicalDebt
    hash[:reporter] = issue.reporter if issue.reporter
    hash[:assignee] = issue.assignee if issue.assignee
    hash[:author] = issue.authorLogin if issue.authorLogin
    hash[:actionPlan] = issue.actionPlanKey if issue.actionPlanKey
    hash[:creationDate] = Api::Utils.format_datetime(issue.creationDate) if issue.creationDate
    hash[:updateDate] = Api::Utils.format_datetime(issue.updateDate) if issue.updateDate
    hash[:fUpdateAge] = Api::Utils.age_from_now(issue.updateDate) if issue.updateDate
    hash[:closeDate] = Api::Utils.format_datetime(issue.closeDate) if issue.closeDate
    hash[:attr] = issue.attributes.to_hash unless issue.attributes.isEmpty()
    if issue.comments.size>0
      hash[:comments] = issue.comments.map { |c| comment_to_hash(c) }
    end
    hash
  end

  def self.comment_to_hash(comment)
    {
        :key => comment.key(),
        :login => comment.userLogin(),
        :htmlText => Internal.text.markdownToHtml(comment.markdownText()),
        :createdAt => Api::Utils.format_datetime(comment.createdAt())
    }
  end

  def self.changelog_to_hash(changelog)
    hash = []
    changelog.changes.each do |change|
      user = changelog.user(change)

      hash_change = {}
      hash_change[:user] = user.login() if user
      hash_change[:creationDate] = Api::Utils.format_datetime(change.creationDate()) if change.creationDate()
      hash_change[:diffs] = []

      change.diffs.entrySet().each do |entry|
        key = entry.getKey()
        diff = entry.getValue()
        hash_diff = {}
        hash_diff[:key] = key
        if key == 'technicalDebt'
          hash_diff[:newValue] = technical_debt_to_hash(Internal.technical_debt.toTechnicalDebt(diff.newValue())) if diff.newValue.present?
          hash_diff[:oldValue] = technical_debt_to_hash(Internal.technical_debt.toTechnicalDebt(diff.oldValue())) if diff.oldValue.present?
        else
          hash_diff[:newValue] = diff.newValue() if diff.newValue.present?
          hash_diff[:oldValue] = diff.oldValue() if diff.oldValue.present?
        end
        hash_change[:diffs] << hash_diff
      end

      hash << hash_change
    end
    hash
  end

  def self.technical_debt_to_hash(technical_debt)
    {
        :days => technical_debt.days(),
        :hours => technical_debt.hours(),
        :minutes => technical_debt.minutes()
    }
  end

end
