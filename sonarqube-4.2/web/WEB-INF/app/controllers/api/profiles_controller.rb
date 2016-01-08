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
require 'json'

class Api::ProfilesController < Api::ApiController

  # GET /api/profiles/list?[language=<language][&project=<project id or key>]
  #
  # Since v.3.3
  #
  # ==== Examples
  # - get all the profiles : GET /api/profiles/list
  # - get all the Java profiles : GET /api/profiles/list?language=java
  # - get the profiles used by the project 'foo' : GET /api/profiles/list?project=foo
  # - get the Java profile used by the project 'foo' : GET /api/profiles/list?project=foo&language=java
  def list
    language = params[:language]
    project_key = params[:project]

    default_profile_by_language = {}
    if project_key.present?
      project = Project.by_key(project_key)
      not_found('Unknown project') unless project
      profiles = Internal.quality_profiles.profiles(project.id).to_a
      if language.present?
        profile = profiles.find {|profile| profile.language == language} if profiles
        # Return default profile if the project is not associate to a profile
        profile = Internal.quality_profiles.defaultProfile(language.to_s) unless profile
      else
        profile = Internal.quality_profiles.defaultProfile(project.language.to_s) if profiles.empty?
      end
      if profile
        # Populate default profile by language to not execute twice the SQL to get default profile
        profiles = [profile]
        default_profile_by_language[profile.language] = profile
      end
    elsif language.present?
      profiles = Internal.quality_profiles.allProfiles().select {|profile| profile.language == language}
    else
      profiles = Internal.quality_profiles.allProfiles().to_a
    end

    # Populate the map of default profile by language by searching for all profiles languages
    # We have to do that as the profiles list do not contain this information (maybe we should add it?)
    profiles.each do |p|
      lang = p.language
      unless default_profile_by_language[lang]
        default_profile_by_language[lang] = Internal.quality_profiles.defaultProfile(lang.to_s)
      end
    end
    profiles = [default_profile_by_language[project.language]] if profiles.empty?

    json = profiles.compact.map { |profile| {:name => profile.name, :language => profile.language, :default => default_profile_by_language[profile.language].name == profile.name } }
    respond_to do |format|
      format.json { render :json => jsonp(json) }
      format.xml { render :xml => xml_not_supported }
      format.text { render :text => text_not_supported }
    end
  end

  # POST /api/profiles/destroy?language=<language>&name=<name>
  def destroy
    verify_post_request
    access_denied unless has_role?(:profileadmin)
    require_parameters :language, :name

    profile = Internal.quality_profiles.profile(params[:name], params[:language])
    if profile
      Internal.quality_profiles.deleteProfile(profile.id())
      Alert.delete_all(['profile_id=?', profile.id()])
    end

    render_success(profile ? 'Profile destroyed' : 'Profile did not exist')
  end

  # POST /api/profiles/set_as_default?language=<language>&name=<name>
  #
  # Since v.3.3
  def set_as_default
    verify_post_request
    profile = Internal.quality_profiles.profile(params[:name], params[:language])
    not_found('Profile not found') unless profile
    Internal.quality_profiles.setDefaultProfile(profile.id)
    render_success
  end

  # GET /api/profiles?language=<language>[&name=<name>]
  def index
    require_parameters :language

    language=params[:language]
    name=params[:name]
    if name.blank?
      @profile=Profile.by_default(language)
    else
      @profile=Profile.find_by_name_and_language(name, language)
    end
    not_found('Profile not found') unless @profile

    @active_rules=filter_rules()

    respond_to do |format|
      format.json { render :json => jsonp(to_json) }
      format.xml { render :xml => to_xml }
      format.text { render :text => text_not_supported }
    end
  end

  # Backup a profile. If output format is xml, then backup is directly returned.
  # GET /api/profiles/backup?language=<language>[&name=my_profile] -v
  def backup
    require_parameters :language

    language = params[:language]
    if (params[:name].blank?)
      profile = Internal.quality_profiles.defaultProfile(language)
    else
      profile = Internal.quality_profiles.profile(params[:name], params[:language])
    end
    not_found('Profile not found') unless profile
    backup = Internal.profile_backup.backupProfile(profile)
    respond_to do |format|
      format.xml { render :xml => backup }
      format.json { render :json => jsonp({:backup => backup}) }
    end
  end

  # Restore a profile backup.
  # curl -X POST -u admin:admin -F 'backup=<my>backup</my>' -v http://localhost:9000/api/profiles/restore
  # curl -X POST -u admin:admin -F 'backup=@backup.xml' -v http://localhost:9000/api/profiles/restore
  def restore
    verify_post_request
    require_parameters :backup

    result = Internal.profile_backup.restore(Api::Utils.read_post_request_param(params[:backup]), true)

    respond_to do |format|
      format.json { render :json => jsonp(validation_result_to_json(result)), :status => 200 }
    end
  end

  private

  def validation_messages_to_json(messages)
    hash={}
    hash[:errors]=messages.getErrors().to_a.map { |message| message }
    hash[:warnings]=messages.getWarnings().to_a.map { |message| message }
    hash[:infos]=messages.getInfos().to_a.map { |message| message }
    hash
  end

  def validation_result_to_json(result)
    hash={}
    hash[:warnings]=result.warnings().to_a.map { |message| message }
    hash[:infos]=result.infos().to_a.map { |message| message }
    hash
  end

  def filter_rules
    conditions=['active_rules.profile_id=?']
    condition_values=[@profile.id]

    if params[:rule_repositories].present?
      conditions<<'rules.plugin_name in (?)'
      condition_values<<params[:rule_repositories].split(',')
    end

    if params[:rule_severities].present?
      conditions<<'failure_level in (?)'
      condition_values<<params[:rule_severities].split(',').map { |severity| Sonar::RulePriority.id(severity) }
    end

    ActiveRule.find(:all, :include => [:rule, {:active_rule_parameters => :rules_parameter}], :conditions => [conditions.join(' AND ')].concat(condition_values))
  end

  def to_json
    result={}
    result[:name]=@profile.name
    result[:language]=@profile.language
    result[:parent]=@profile.parent_name if @profile.parent_name.present?
    result[:default]=@profile.default_profile?

    rules=[]
    @active_rules.each do |active_rule|
      hash={}
      hash[:key]=active_rule.rule.plugin_rule_key
      hash[:repo]=active_rule.rule.plugin_name
      hash[:severity]=active_rule.priority_text
      hash[:inheritance]=active_rule.inheritance if active_rule.inheritance
      params_hash=[]
      active_rule.active_rule_parameters.each do |param|
        params_hash<<{:key => param.name, :value => param.value}
      end
      hash[:params]=params_hash unless params_hash.empty?
      rules<<hash
    end
    result[:rules]=rules unless rules.empty?

    alerts=[]
    @profile.valid_alerts.each do |alert|
      alert_hash={:metric => alert.metric.key, :operator => alert.operator}
      alert_hash[:error]=alert.value_error if alert.value_error.present?
      alert_hash[:warning]=alert.value_warning if alert.value_warning.present?
      alerts<<alert_hash
    end
    result[:alerts]=alerts unless alerts.empty?
    [result]
  end

  def to_xml
    xml = Builder::XmlMarkup.new(:indent => 0)
    xml.instruct!

    xml.profile do
      xml.name(@profile.name)
      xml.language(@profile.language)
      xml.parent(@profile.parent_name) if @profile.parent_name.present?
      xml.default(@profile.default_profile?)

      @active_rules.each do |active_rule|
        xml.rule do
          xml.key(active_rule.rule.plugin_rule_key)
          xml.repo(active_rule.rule.plugin_name)
          xml.severity(active_rule.priority_text)
          xml.inheritance(active_rule.inheritance) if active_rule.inheritance
          active_rule.active_rule_parameters.each do |param|
            xml.param do
              xml.key(param.name)
              xml.value(param.value)
            end
          end
        end
      end

      @profile.valid_alerts.each do |alert|
        xml.alert do
          xml.metric(alert.metric.key)
          xml.operator(alert.operator)
          xml.error(alert.value_error) if alert.value_error.present?
          xml.warning(alert.value_warning) if alert.value_warning.present?
        end
      end
    end
  end

end
