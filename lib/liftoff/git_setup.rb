module Liftoff
  class GitSetup
    def initialize(config)
      @config = config
    end

    def setup
      if @config.configure_git
        generate_files

        if needs_git_init?
          initialize_repo
          create_initial_commit
        end
      end
    end

    private

    def generate_files
      file_manager.generate('gitignore', '.gitignore', @config)
      file_manager.generate('gitattributes', '.gitattributes', @config)
    end

    def initialize_repo
      `git init`
      `git remote add origin #{@config.git_url}`
    end

    def create_initial_commit
      `git checkout -b #{@config.build_branch}`
      `git add -A`
      `git commit --message='Initial Project'`
      `git push -f origin #{@config.build_branch}`
    end

    def needs_git_init?
      `git rev-parse --git-dir 2>/dev/null`.strip.empty?
    end

    def file_manager
      @file_manager ||= FileManager.new
    end
  end
end
