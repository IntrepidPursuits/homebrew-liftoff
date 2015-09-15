module Liftoff
  class CredentialManager
    def initialize()
      @jenkins_token_name = "jenkins_token"
      @jenkins_username = "jenkins_user"
      @github_token_name = "github"
    end

    def git_token_exists?
      (git_token.length > 0)
    end

    def git_token
      read_token(@github_token_name)
    end

    def save_git_token(token)
      write_token(token, @github_token_name)
    end

    def jenkins_token_exists?
      (jenkins_token.length > 0)
    end

    def jenkins_token
      read_token(@jenkins_token_name)
    end

    def save_jenkins_token(token)
      write_token(token, @jenkins_token_name)
    end

    def save_jenkins_username(username)
      write_token(username, @jenkins_username)
    end

    private

    def setup_token_directory
      FileUtils::mkdir_p(token_directory)
    end

    def token_directory
      "#{ENV['HOME']}/.intrepid/ios"
    end

    def write_token(token, file)
      setup_token_directory
      File.write(token_file_path(file), token)
    end

    def read_token(token_file)
      token = ""
      if File.exists?(token_file_path(token_file))
        token = File.read(token_file_path(token_file))
      end
      token
    end

    def token_file_path(filename)
      "#{token_directory}/#{filename}"
    end
  end
end
