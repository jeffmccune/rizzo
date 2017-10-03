module Rzo
  ##
  # Mix-in module to handle all config parsing.  Requires options to 
  module ConfigParsing
    attr_reader :config

    ##
    # Delegated method to mock with fixture data.
    def load_rizzo_config(fpath)
      config_file = Pathname.new(fpath).expand_path
      raise ErrorAndExit, "Cannot read config file #{config_file}" unless config_file.readable?
      config = JSON.parse(config_file.read)
      log.debug "Loaded #{config_file}"
      config
    rescue JSON::ParserError => e
      raise ErrorAndExit, "Could not parse rizzo config #{config_file} #{e.message}"
    end

    ##
    # Load rizzo configuration.  Populate @config.
    #
    # Read rizzo configuration by looping through control repos and stopping
    # at first match and merge on top of local, defaults (~/.rizzo.json)
    def load_config!(config_file)
      config = load_rizzo_config(config_file)
      validate_personal_config!(config)
      repos = reorder_repos(config['control_repos'])
      config['control_repos'] = repos
      @config = load_repo_configs(config, repos)
      debug "Merged configuration: \n#{JSON.pretty_generate(@config)}"
      # TODO: Move these validations to an instance method?
      validate_complete_config!(@config)
      # validate_forwarded_ports(@config)
      # validate_ip_addresses(@config)
      @config
    end

    ##
    # Given a list of repository paths, load .rizzo.json from the root of each
    # repository and return the result merged onto config.  The merging
    # behavior is implemented by
    # [deep_merge](http://www.rubydoc.info/gems/deep_merge/1.1.1)
    #
    # @param [Hash] config the starting config hash.  Repo config maps will be
    #   merged on top of this starting map.
    #
    # @param [Array] repos the list of repositories to load .rizzo.json from.
    #
    # @return [Hash] the merged configuration hash.
    def load_repo_configs(config = {}, repos = [])
      repos.each_with_object(config.dup) do |repo, hsh|
        fp = Pathname.new(repo).expand_path + '.rizzo.json'
        if fp.readable?
          hsh.deep_merge!(load_rizzo_config(fp))
        else
          log.debug "Skipped #{fp} (it is not readable)"
        end
      end
    end

    ##
    # Memoized method to return the fully qualified path to the current rizzo
    # project directory, based on the pwd.  The project directory is the
    # dirname of the full path to a `.rizzo.json` config file.  Return false
    # if not a project directory.  ~/.rizzo.json is considered a personal
    # configuration and not a project configuration.
    #
    # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
    def project_dir(path)
      return @project_dir unless @project_dir.nil?
      rizzo_file = Pathname.new("#{path}/.rizzo.json")
      personal_config = Pathname.new(File.expand_path('~/.rizzo.json'))
      iterations = 0
      while @project_dir.nil? && iterations < 100
        iterations += 1
        if readable?(rizzo_file.to_s) && rizzo_file != personal_config
          @project_dir = rizzo_file.dirname.to_s
        else
          rizzo_file = rizzo_file.dirname.dirname + '.rizzo.json'
          @project_dir = false if rizzo_file.dirname.root?
        end
      end
      @project_dir
    end
    # rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

    ##
    # Given a list of control repositories, determine if the user's runtime
    # pwd is in a control repository.  If it is, move that control repository
    # to the top level.  If the user is inside a control repository and
    def reorder_repos(repos = [])
      if path = project_dir(pwd)
        new_repos = repos - [path]
        new_repos.unshift(path)
      else
        repos
      end
    end

    # helper method to to stub in tests
    def readable?(path)
      File.readable?(path)
    end
  end
end
