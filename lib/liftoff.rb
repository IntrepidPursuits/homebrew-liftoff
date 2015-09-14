require 'optparse'
require 'fileutils'
require 'yaml'
require 'erb'
require 'etc'
require 'find'
require 'net/https'
require 'json'

require 'highline/import'
require 'xcodeproj'

require 'liftoff/cli'
require "liftoff/dependency_manager_coordinator"
require "liftoff/dependency_manager"
require "liftoff/dependency_managers/carthage"
require "liftoff/dependency_managers/cocoapods"
require "liftoff/dependency_managers/null_dependency_manager"
require 'liftoff/settings_generator'
require 'liftoff/configuration_parser'
require 'liftoff/credential_manager'
require 'liftoff/deprecation_manager'
require 'liftoff/file_manager'
require 'liftoff/jenkins_manager'
require 'liftoff/json_helper'
require 'liftoff/git_setup'
require 'liftoff/git_repo_manager'
require 'liftoff/launchpad'
require 'liftoff/object_picker'
require 'liftoff/option_fetcher'
require 'liftoff/project'
require 'liftoff/project_builder'
require 'liftoff/project_configuration'
require 'liftoff/string_renderer'
require 'liftoff/template_finder'
require 'liftoff/template_generator'
require 'liftoff/version'
require 'liftoff/xcodeproj_helper'
require 'liftoff/xcodeproj_monkeypatch'
