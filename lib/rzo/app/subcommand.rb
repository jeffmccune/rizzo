require 'pathname'
require 'rzo/logging'
require 'deep_merge'
require 'rzo/app/config_validation'
module Rzo
  class App
    # The base class for subcommands
    # rubocop:disable Metrics/ClassLength
    class Subcommand
      include Logging
      extend Logging
      # The options hash injected from the application controller via the
      # initialize method.
      attr_reader :opts
      attr_reader :pwd
      attr_accessor :config

      # Initialize a subcommand with options injected by the application
      # controller.
      #
      # @param [Hash] config see the #load_config! method in the App class.
      #
      # @param [Hash] opts the Options hash initialized by the Application
      # controller.
      def initialize(opts = {}, stdout = $stdout, stderr = $stderr, config = nil)
        @config = config
        @opts = opts
        @stdout = stdout
        @stderr = stderr
        @config = config
        reset_logging!(opts)
        @pwd = Dir.pwd
      end

      ##
      # Default run method.  Override this method in a subcommand sub-class
      #
      # @return [Fixnum] the exit status of the subcommand.
      def run
        error "Implement the run method in subclass #{self.class}"
        1
      end

      private

      ##
      # Check for duplicate forwarded host ports across all hosts and exit
      # non-zero with an error message if found.
      def validate_forwarded_ports(config)
        host_ports = []
        [*config['nodes']].each do |node|
          [*node['forwarded_ports']].each do |hsh|
            port = hsh['host'].to_i
            raise_port_err(port, node['name']) if host_ports.include?(port)
            host_ports.push(port)
          end
        end
        log.debug "host_ports = #{host_ports}"
      end

      ##
      # Check for duplicate forwarded host ports across all hosts and exit
      # non-zero with an error message if found.
      def validate_ip_addresses(config)
        ips = []
        [*config['nodes']].each do |node|
          if ip = node['ip']
            raise_ip_err(ip, node['name']) if ips.include?(ip)
            ips.push(ip)
          end
        end
        log.debug "ips = #{ips}"
      end

      ##
      # Helper to raise a duplicate port error
      def raise_port_err(port, node)
        raise ErrorAndExit, "host port #{port} on node #{node} " \
          'is a duplicate.  Ports must be unique.  Check .rizzo.json ' \
          'files in each control repository for duplicate forwarded_ports entries.'
      end

      ##
      # Helper to raise a duplicate port error
      def raise_ip_err(ip, node)
        raise ErrorAndExit, "host ip #{ip} on node #{node} " \
          'is a duplicate.  IP addresses must be unique.  Check .rizzo.json ' \
          'files in each control repository for duplicate ip entries'
      end

      ##
      # Write a file by yielding a file descriptor to the passed block.  In the
      # case of opening a file, the FD will automatically be closed.
      def write_file(filepath)
        case filepath
        when 'STDOUT' then yield @stdout
        when 'STDERR' then yield @stderr
        else File.open(filepath, 'w') { |fd| yield fd }
        end
      end
    end
  end
end
