require 'github'

class Request
  module Github
    extend ActiveSupport::Concern

    class << self
      def reject?(repository, commit)
        repository.private? || skipped?(commit) || github_pages?(commit)
      end

      def skipped?(commit)
        commit.message.try(:match, /\[ci ([\w ]*)\]/i) && $1.downcase == 'skip'
      end

      def github_pages?(commit)
        commit.branch.try(:match, /gh[-_]pages/i)
      end
    end

    module ClassMethods
      def create_from_github_payload(payload, token)
        data = ::Github::ServiceHook::Payload.new(payload)
        commit = data.commits.last

        if commit && !Github.reject?(data.repository, commit)
          attributes = { :source => :github, :payload => payload, :commit => Commit.create!(commit.to_hash), :token => token }
          repository = Repository.find_or_create_by_github_repository(data.repository)
          repository.requests.create!(attributes)
        end
      end
    end
  end
end