# encoding: UTF-8
require 'octokit'

module Mkghrepo
  # Repo provides an interface to github repos
  class Repo
    def initialize(token)
      # stack = Faraday::RackBuilder.new do |builder|
      #   builder.response :logger
      #   builder.use Octokit::Response::RaiseError
      #   builder.adapter Faraday.default_adapter
      # end
      # Octokit.middleware = stack
      @client = Octokit::Client.new(access_token: token)
    end

    def create_repo(repo, private = false)
      if repo.include? '/'
        organization = repo.rpartition('/').first
        repo = repo.rpartition('/').last
        @client.create_repository(repo,
                                  private: private,
                                  organization: organization)
      else
        @client.create_repository(repo,
                                  private: private)
      end
    end

    def create_team(repo, team_name, permissions)
      organization = repo.rpartition('/').first
      @client.create_team(organization,
                          name: team_name,
                          repo_names: [repo],
                          permission: permissions)
    end

    def add_user_to_team(user, team_id)
      @client.add_team_member(team_id, user)
    end
  end
end
