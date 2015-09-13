module Liftoff
  class CLI
    def initialize(argv)
      @argv = argv
      @options = {}
    end

    def run
      parse_command_line_options
      LaunchPad.new.liftoff @options
    end

    private

    def parse_command_line_options
      global_options.parse!(@argv)
      @options[:path] = @argv.first
    end

    def global_options
      OptionParser.new do |opts|
        opts.banner = 'usage: liftoff [-v | --version] [-h | --help] [config options] [path]'

        opts.on('-v', '--version', 'Display the version and exit') do
          puts "Version: #{Liftoff::VERSION}"
          exit
        end

        opts.on('-h', '--help', 'Display this help message and exit') do
          puts opts
          exit
        end

        opts.on('--no-git', 'Disable git creation') do |configure_git|
          @options[:configure_git] = false
        end

        opts.on('--no-jenkins', 'Disable Jenkins job creation') do |disable_jenkins|
          @options[:configure_jenkins] = false
        end

        opts.on('--template [TEMPLATE NAME]', 'Use the specified project template') do |template_name|
          @options[:project_template] = template_name
        end

        opts.on('-n', '--name [PROJECT_NAME]', 'Set project name') do |name|
          @options[:project_name] = name
        end

        opts.on('-p', '--prefix [PREFIX]', 'Set project prefix') do |prefix|
          @options[:prefix] = prefix
        end

        opts.on('--test-target-name [TEST_TARGET_NAME]', 'Set the name of the unit test target') do |test_target_name|
          @options[:test_target_name] = test_target_name
        end
      end
    end
  end
end
