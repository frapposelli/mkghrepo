# encoding: UTF-8
require 'logger'
require 'slop'

module Mkghrepo
  # CLI Class takes care of all the plubing related to the CLI commands and
  # option parsing, consuming other classes to operate against Github Repos.
  #
  # Disabling ClassLength cop due to parse_options inflating the line numbers.
  class CLI # rubocop:disable Metrics/ClassLength
    def setup_logging(level)
      start = Time.now
      @logger = Logger.new(STDOUT)
      @logger.level = level
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
      @logger.formatter = proc do |severity, _datetime, _progname, msg|
        now = Time.now
        "[#{severity}][#{(now - start).round}] #{msg}\n"
      end
    end

    def initialize
      if ENV['MKGHREPO_LOG'].nil?
        setup_logging(Logger::INFO)
      else
        setup_logging(Logger.const_get(ENV['MKGHREPO_LOG'].upcase))
      end
    end

    # Parse CLI options with 'slop', disabling the MethodLength cop for this
    # particular method as we can't really make it shorter.
    def parse_options # rubocop:disable Metrics/MethodLength
      opts = Slop.parse do |o|
        o.banner = 'Usage: mkghrepo [options] <filename>'
        o.separator ''
        o.separator 'Repository options:'
        o.bool '-p',
               '--private',
               'make the repository private',
               default: false
        o.bool '-t',
               '--create-team',
               'creates a team called "<foo>-write", default is false',
               default: false
        o.string '--token',
                 'sets github token, defaults from GITHUB_TOKEN',
                 default: ENV['GITHUB_TOKEN']
        o.separator ''
        o.separator 'Other options:'
        o.bool '-h', '--help', 'print this help'
        o.on '-v', '--version', 'print the version' do
          puts VERSION
          exit
        end
      end

      input_sanitization(opts)

      opts
    end

    def input_sanitization(opts)
      @logger.debug("Options: #{opts.to_hash} Arguments: #{opts.arguments}")

      # if help is required, just print it and exit
      if opts.help?
        puts opts
        exit
      end

      return unless opts[:token].nil?

      # Fail if token is not available
      @logger.fatal('Token is required')
      puts opts
      exit 1
    end

    def process_file(file, client, opts)
      # We received one or more file arguments, let's open up the first one and
      # start reading it.
      @logger.debug("Opening #{file} for parsing...")
      unless File.exist?(file)
        # File not found, no point in continuing
        @logger.fatal("File #{file} not found")
        exit 1
      end
      File.open(file, 'r') do |f|
        f.each_line do |a|
          # Treat each line as a separate repo
          process_lines(a, client, opts[:private], opts[:create_team])
        end
      end
    end

    def process_stdin(client, opts)
      # We have no file arguments, start reading from STDIN and treat every line
      # as a separate repo.
      @logger.warn('No file arguments, reading from stdin...')
      begin
        STDIN.read.split("\n").each do |a|
          # Treat each line as a separate repo
          process_lines(a, client, opts[:private], opts[:create_team])
        end
      rescue Interrupt
        # Trap a CTRL+C event and exit gracefully
        @logger.warn('Exiting...')
        exit 130
      end
    end

    def process_lines(line, client, private, create_team)
      # Split the line using space as delimiter, format is:
      # <org>/<repo> <user1> <user2> ... <userN>
      #  or
      # <repo>
      @logger.debug("processing #{line.strip}")
      matches = line.split(' ')
      repo = matches[0]
      create_repo(client, repo, private)

      # If no users are specified or create_team was not enabled
      return if matches.length < 2 || create_team == false
      # create team and whatever
      if repo.include? '/'
        process_team(client, repo, matches[1..matches.count])
      else
        @logger.warn("Not creating Team for #{repo}, only orgs support teams")
      end
    end

    def process_team(client, repo, users)
      team = create_team(client, repo)
      users.each do |user|
        add_user_to_team(client, user, team.id)
      end
    end

    def parse_error(object, e)
      case
      when !e.errors.first[:message].nil?
        # Print a human readable error and carry on.
        @logger.error("Can't process #{object}: #{e.errors.first[:message]}")
      when e.errors.length > 0
        # Can't find a human readable error, just dump the error hash and be
        # done with it.
        @logger.error("Can't process #{object}: #{e.errors}")
      else
        # Apparently some errors are not correctly formatted so we just dump
        # the whole ugly message to screen.
        @logger.error("Can't process #{object}: #{e.message}")
      end
    end

    def create_repo(client, repo, private)
      @logger.debug("Creating repo named: #{repo}")
      client.create_repo(repo, private)
    rescue Octokit::Error => e
      parse_error(repo, e)
    else
      @logger.info("Succesfully created repository: #{repo}")
    end

    def create_team(client, repo)
      team_name = repo.rpartition('/').last + '-write'
      @logger.debug("Creating team named: #{team_name}")
      team = client.create_team(repo, team_name, 'push')
    rescue Octokit::Error => e
      parse_error(team_name, e)
    else
      @logger.info("Succesfully created team '#{team_name}' for: #{repo}")
      team
    end

    def add_user_to_team(client, user, team_id)
      @logger.debug("Adding user #{user} to team id: #{team_id}")
      client.add_user_to_team(user, team_id)
    rescue Octokit::Error => e
      parse_error(user, e)
    else
      @logger.info("Succesfully added user '#{user}' on team id: #{team_id}")
    end
  end
end
