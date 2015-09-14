module Liftoff
  class JenkinsManager
    def initialize(config)
      @config = config
      @client = nil
      @jenkins_username = ""
      @jenkins_token = ""
      @config_template_name = "ios-template-standard"
      @old_config_contents = ""
      @new_config_contents = ""
      @jenkins_base_url = "http://build.intrepid.io:8080"
      @credentialManager = CredentialManager.new()
    end

    def setup
      if @config.configure_jenkins
        if needs_authorization?
          authorize_user
        end
        
        authorize_client
        prepare_for_job
        prepare_config_file
        create_job
      end
    end

    def needs_authorization?
      token_exists? == false
    end

    def authorize_user
      puts "Authorizing Jenkins Build Server"
      @jenkins_username = ask "Jenkins Username: "
      @credentialManager.save_jenkins_username(@jenkins_username)

      puts "Setting up Jenkins requires you to input your API token."
      ask "Log in to Jenkins and navigate to #{jenkins_base_url}/me/configure (Press Enter)"
      ask "If no API Token exists, enter a random string of characters. This is saved in plaintext, don't use a password (Press Enter)"
      
      token = @credentialManager.jenkins_token
      loop do
        token = ask "Copy and Paste Your API Token: "
        break if token.length > 0
      end

      @jenkins_token = token
      @credentialManager.save_jenkins_token(@jenkins_token)
    end

    def job_exists?
      puts "Checking for existing Jenkins job"
      @client.job.exists?("#{@config.repo_name}")
    end

    private

    def authorize_client
      @client = JenkinsApi::Client.new(
        :server_url => "#{@jenkins_base_url}", 
        :username => "#{@jenkins_username}", 
        :password => "#{@jenkins_token}"
        )
    end

    def prepare_for_job
      puts "Preparing to create Jenkins job"
      raise "A Jenkins job with this name already exists. Contact an admin" unless job_exists?

      @old_config_contents = @client.job.get_config("#{@config_template_name}")
      raise "Unable to fetch iOS Project Template. Contact an admin" unless (@old_config_contents.length > 0)
    end

    def prepare_config_file
      puts "Preparing job configuration file"

      # Replace Description
      project_description = "Intrepid Pursuits \r\n Github Repository: #{@config.git_http_url} \r\n Created By Liftoff Version __VERSION__"
      @new_config_contents = @old_config_contents.sub("INTREPID_LIFTOFF_SCRIPT_PROJECT_DESCRIPTION", project_description)
      
      # Replace github URL
      @new_config_contents = @new_config_contents.sub("INTREPID_LIFTOFF_SCRIPT_SSH_GIT_REPO_URL", @config.git_url)
      
      # Replace project target name
      @new_config_contents = @new_config_contents.sub("INTREPID_LIFTOFF_SCRIPT_PROJECT_TARGET_NAME", @config.project_name)

      # Replace email notification body with project names
      @new_config_contents = @new_config_contents.sub("INTREPID_LIFTOFF_SCRIPT_EMAIL_CONTENT_NAME", @config.project_name)
      @new_config_contents = @new_config_contents.sub("INTREPID_LIFTOFF_SCRIPT_EMAIL_CONTENT_URL_NAME", @config.repo_name)
      
      # Collect emails to notify when build updates
      all_emails = []
      email_to_add = ""
      loop do
        email_to_add = ask "Enter an email to receive build updates (Blank to skip): "
        if email_to_add.length > 0
          all_emails += [email_to_add] if email_to_add.length > 0
          puts "Added #{email_to_add} to list of recipients"
        end
        
        break if email_to_add.length == 0
      end

      # Replace email recipients 
      @new_config_contents = @new_config_contents.sub("INTREPID_LIFTOFF_SCRIPT_EMAIL_CONTENT_RECIPIENTS", all_emails.join(', '))
      
    end

    def create_job
      puts "Creating Jenkins job"
      @client.job.create("#{@config.repo_name}", @new_config_contents)
    end

    def token_exists?
      @credentialManager.jenkins_token_exists?
    end
  end
end
