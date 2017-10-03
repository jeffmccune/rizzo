require 'rzo/app/subcommand'
module Rzo
  class App
    ##
    # Load all rizzo config files and print the config
    class Config < Subcommand
      def run
        exit_status = 0
        write_file(opts[:output]) { |fd| fd.puts(JSON.pretty_generate(config)) }
        exit_status
      end
    end
  end
end
