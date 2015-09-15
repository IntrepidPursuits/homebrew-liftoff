module Liftoff
  class GitRepoManager
    def initialize(config)
      @config = config
      @token = ""
      @organization_id = 0
      @team_id = 0
      @team_slug = "ios-developers"
      @organization_string = "IntrepidPursuits"
      @git_api_base = "https://api.github.com"
      @jenkins_notify_base_url = "http://build.intrepid.io:8080/git/notifyCommit?url="
      @git_client = nil
      @git_user = nil
      @git_repo = nil
      @git_dev_ref = nil
      @git_hook = nil
    end

    def setup
      if @config.configure_git
        puts "Setting up remote Github Repository"
        if needs_authorization?
          authorize_user
          authorize_client
        end

        create_repo unless repo_exists?
        create_branches unless branch_exists?
        create_webhooks unless hook_exists?
      end
    end

    def needs_authorization?
      (oauth_token_exists? == false)
    end 

    def authorize_user
      puts "Authorizing GitHub"
      auth_headers = {}
      username = ask "Github Username: "
      github_pass = ask("Github Password: ") {|q| q.echo = false}
      github_2fa_token = ask("Github 2FA Token (Enter for none): ")

      @git_client = Octokit::Client.new(:login => username, :password => github_pass)
      auth_headers = {"X-GitHub-OTP" => github_2fa_token} if github_2fa_token 

      new_auth = @git_client.create_authorization(
        :scopes => ["read:org", "write:repo_hook", "repo", "user"], 
        :note => "#{@config.company} - Blastoff Script - #{Liftoff::VERSION}",
        :headers => auth_headers
        )
      @token = new_auth.token
      CredentialManager.new().save_git_token(@token)
    end

    def user_is_on_team?
      on_team = @git_client.organization_member?(@organization_string, @git_user.login)
      raise "Error: You are not a member of the Intrepid Github Organization. Contact an admin" unless on_team
      user_is_on_ios_team?
    end

    def authorize_client
      get_local_token
      @git_client = Octokit::Client.new(:access_token => @token)
      if @git_client
        @git_user = @git_client.user
        username = @git_user.login
        raise "Unable to get user credentials" unless username
      end
    end

    private

    def user_is_on_ios_team?
      all_teams = @git_client.organization_teams(@organization_string)
      ios_team = nil
      all_teams.each do |team|
        next unless team.slug == @team_slug
        ios_team = team
      end

      @team_id = ios_team.id
      is_on_ios_team = @git_client.team_member?(@team_id, @git_user.login)
      raise "Error: You are not a member of the iOS Developers team on the Intrepid Github Organization. Contact an admin" unless is_on_ios_team
      is_on_ios_team
    end

    def oauth_token_exists?
      CredentialManager.new().git_token_exists?
    end

    def get_local_token
      raise "Error: Couldn't find oauth token file" unless oauth_token_exists?
      @token = CredentialManager.new().git_token
    end

    def create_repo
      puts "Creating Github Repo: #{@config.repo_name}"
      @git_repo = @git_client.create_repository(@config.repo_name, {
        :description => "#{@config.repo_name} by #{@config.company}",
        :private => "true",
        :has_issues => "false",
        :has_wiki => "true",
        :has_downloads => "false",
        :organization => @organization_string,
        :team_id => @team_id,
        :auto_init => true,
        })

      raise "Error: Failed to create repo. Contact an admin" unless @git_repo
    end

    def repo_exists?
      @git_client.repository?(git_repo_name)
    end

    def create_branches
      puts "Creating Branches"
      begin
        master_ref = @git_client.ref(git_repo_name, "heads/master")
        @git_dev_ref = @git_client.create_ref(git_repo_name, "heads/develop", master_ref.object.sha)
      rescue
        puts "Non-Fatal: Failed creating develop branch"
      end
    end

    def branch_exists?
      begin
        @git_client.ref(git_repo_name, "heads/develop")
      rescue
        return false
      end
      true
    end

    def create_webhooks
      puts "Creating Web Hooks"
      begin
        @git_hook = @git_client.create_hook(git_repo_name, "web", {
          :url => "#{@jenkins_notify_base_url}#{@git_repo.html_url}&branches=#{@config.build_branch}",
          :content_type => "json",
          },
          {
            :events => ["push"],
            :active => true
            })
      rescue
        puts "Non-Fatal: Failed creating jenkins webhook"
      end
    end

    def hook_exists?
      all_hooks = @git_client.hooks(git_repo_name)
      (all_hooks.length > 0)
    end

    def git_repo_name
      "#{@organization_string}/#{@config.repo_name}"
    end

  end
end
