module Liftoff
  class JenkinsManager
    def initialize(config)
      @config = config
      @client = nil
      @jenkins_username = ""
      @jenkins_token = ""
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
      until token.length > 0 do
        token = ask "Copy and Paste Your API Token: "
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

      @old_config_contents = @client.get_config?("#{@config.repo_name}")
      raise "Unable to fetch iOS Project Template. Contact an admin" unless (@old_config_contents.length > 0)
    end

    def prepare_config_file
      puts "Preparing job configuration file"
      xml_doc = Nokogiri::XML(@old_config_contents)

      # Replace github URL
      xml_doc.at_xpath('//url').content = "#{git_url}"

      # Replace project target name
      val_to_replace = "CHANGE_THIS_VALUE_TO_YOUR_PROJECT_TARGET_NAME"
      properties_content = xml_doc.at_xpath('//propertiesContent').content
      properties_content.gsub(val_to_replace, "#{@config.project_name}")
      properties_content.gsub("\n", "&#xd;")
      xml_doc.at_xpath('//propertiesContent').content = properties_content

      # Replace email notification
      val_to_replace = "$SHORT_NAME"
      notification_content = xml.at_xpath('//defaultContent').content
      notification_content.gsub(val_to_replace, "#{@config.repo_name}")

      all_emails = []
      email_to_add = ask "Enter an email to receive build updates (Blank to skip): "

      unless (email_to_add.length == 0) do
        puts "Added #{email_to_add} to list of recipients"
        all_emails += [email_to_add]
        email_to_add = ask "Enter an email to receive build updates (Blank to skip): "
      end

      xml.at_xpath('//recipientList').content = all_emails.join(', ')
      @new_config_contents = xml.to_xml
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
