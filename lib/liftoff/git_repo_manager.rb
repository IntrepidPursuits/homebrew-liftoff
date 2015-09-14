module Liftoff
  class GitRepoManager
    def initialize(config)
      @config = config
      @token = ""
      @organization_id = 0
      @team_id = 0
      @team_slug = "ios-developers"
      @organization_string = "IntrepidPursuits"
      @jenkins_notify_base_url = "http://build.intrepid.io:8080/git/notifyCommit?url="
    end

    def setup
      if @config.configure_git
        puts "Setting up remote Github Repository"
        if needs_authorization? == false
          get_local_token
          user_is_on_team?
        else
          authorize_user
        end

        create_repo
        create_branches
        create_webhooks
      end
    end

    def needs_authorization?
      oauth_token_exists? == false
    end 

    def authorize_user
      puts "Authorizing GitHub"
      username = ask "Github Username: "
      github_pass = ask("Github Password: ") {|q| q.echo = false}

      uri = URI('https://github.com/login/oauth/authorize')
      payload ={
        "scope" => ["read:org","write:repo_hook","repo","user"],
        "note" => "#{@config.company} - Blastoff Script - #{Liftoff::VERSION}"
      }

      req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})
      req.use_ssl = true
      req.body = JSONHelper.new().generate_json(payload)
      req.basic_auth '#{username}', '#{github_pass}'
      res = Net::HTTP.start(uri.hostname, uri.port) {|http|
        http.request(req)
      }

      if res.header.code == "201"
        parsed_json = JSON.parse(res.body)
        @token = parsed_json["token"]
        CredentialManager.new().save_git_token(@token)
      else
        puts response.header
        puts response.body
        puts "======================================="
        puts "Error: Unable to authenticate to GitHub"
        if res.header.code == "401"
          puts "Note: Encountered a 401. Do you have two-factor enabled on GitHub?"
          raise "Two-Factor Authentication is not currently supported"
        end
      end
    end

    def user_is_on_team?
      puts "Check if the user is on the Intrepid Team"
      url = "https://api.github.com/user/orgs"
      parsed_json = simpleGETRequest(url)
      parsed_json.each do |org|
        if org["login"].include? "#{organization_string}"
          @organization_id = org["id"]
          return user_is_on_ios_team?
        end
      end
      
      puts "Error: You are not a member of the Intrepid Github Organization. Contact an admin"
      exit
    end

    private

    def user_is_on_ios_team?
      url = "https:/api.github.com/orgs/#{@organization_id}/teams"
      parsed_json = simpleGETRequest(url)
      parsed_json.each do |team|
        slug = team["slug"]
        if slug == @team_slug
          @team_id = team["id"]
          return true
        end
      end

      puts "Error: You are not a member of the iOS Developers team on the Intrepid Github Organization. Contact an admin"
      exit
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
      url = "https://api.github.com/orgs/#{organization_id}/repos"
      payload ={
        "name" => @config.repo_name,
        "description" => "#{@config.project_name} by #{company}",
        "has_wiki" => true,
        "auto_init" => true,
        "team_id" => @team_id,
      }
      res = simplePOSTRequest(url, payload)
      if res.header.code != "201"
        puts res.header
        puts res.body
        raise "Error: Encountered a non 201 status code while creating repository"
      end

      parsed_json = JSON.parse(res.body)
      @config.git_api_url = parsed_json["url"]
      @config.git_url = parsed_json["git_url"]
      @config.git_http_url = parsed_json["html_url"]
      @config.git_web_hook_url = parsed_json["hooks_url"]
    end

    def create_branches
      puts "Creating Branches"
      url = "#{@config.git_api_url}/git/refs/heads"
      json_response = simpleGETRequest(url)
      commit = json_response["commit"]
      sha = commit["sha"]

      if sha
        url = "#{@config.git_api_url}/git/refs"
        payload ={
          "ref" => "refs/heads/develop",
          "sha" => sha
        }
        res = simplePOSTRequest(url, payload)
        if res.header.code != "201"
          puts "Non-Fatal: Encountered a non 201 status code while creating the develop branch"
        end
      end
    end

    def create_webhooks
      puts "Creating Web Hooks"
      jenkins_url = "#{@jenkins_notify_base_url}#{@config.git_http_url}&branches=#{@config.build_branch}"
      secret = "93b3d9ab3cd1e87d3f5ffa34f"

      payload ={
        "name" => "jenkins",
        "active" => true,
        "events" => ["push"],
        "config" => {
          "url" => jenkins_url,
          "content_type" => "json",
          "secret" => secret,
        }
      }

      uri = URI(@config.git_web_hook_url)
      http = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})
      http.headers['X-Hub-Signature'] = 'sha1='+OpenSSL::HMAC.hexdigest(HMAC_DIGEST, secret, payload)
      http.headers["Authorization"] = "token #{@token}"
      http.use_ssl = true
      http.body = JSONHelper.new().generate_json(payload)
      res = Net::HTTP.start(uri.hostname, uri.port) {|req|
        req.request(http)
      }
      
      if res.header.code != "201"
        puts res.header
        puts res.body
        puts "Non-Fatal: Encountered a non 201 status code while creating the webhook"
      end
    end

    def simpleGETRequest(url)
      uri = URI.parse(url)

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)

      if @token
        request["Authorization"] = "token #{@token}"
      end

      response = http.request(request)
      JSON.parse(res.body)
    end

    def simplePOSTRequest(url, payload)
      uri = URI(url)
      req = Net::HTTP::Post.new(uri, initheader = {'Content-Type' =>'application/json'})
      req.use_ssl = true
      req.body = JSONHelper.new().generate_json(payload)

      if @token
        request["Authorization"] = "token #{@token}"
      end

      Net::HTTP.start(uri.hostname, uri.port) {|http|
        http.request(req)
      }
    end
  end
end
