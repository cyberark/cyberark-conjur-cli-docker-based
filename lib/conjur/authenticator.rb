module Conjur
  # Keeps a fresh Conjur access token in a named file by re-authenticating as needed.
  class Authenticator
    require 'tempfile'
    require 'fileutils'

    TOKEN_LIFESPAN = ( ENV['CONJUR_TOKEN_LIFESPAN'] || 5 * 60 ).to_i.seconds
    DELAY = ( ENV['CONJUR_TOKEN_REFRESH_DELAY'] || 10 ).to_i.seconds

    attr_reader :authenticate, :filename

    # +authenticate+ should be a proc that authenticates with Conjur and returns an 
    # access token as a Hash.
    def initialize authenticate, filename
      @authenticate = authenticate
      @filename = filename
    end

    class << self
      def default_filename
        "/run/conjur-access-token"
      end

      # Check the token every +DELAY+ seconds and refresh it if it's out of date. 
      def run authenticate:, filename: default_filename
        while true
          authenticator = Authenticator.new(authenticate, filename)
          authenticator.refresh unless authenticator.fresh?
          sleep DELAY
        end
      end
    end

    def fresh?
      token && (token_age <= TOKEN_LIFESPAN)
    end

    # Perform atomic replacement of the token
    def refresh
      token = authenticate.call
      file = Tempfile.new('conjur-access-token.')
      begin
        file.write JSON.pretty_generate(token)
        file.close
        FileUtils.mv file.path, filename
        Conjur.log << "Refreshed Conjur auth token to #{filename.inspect}\n" if Conjur.log
      ensure
        file.unlink
      end
    rescue
      $stderr.puts $!
    end

    def token
      return false if @token == false
      @token ||= load_token
    end

    protected

    def random nbytes = 12
      @random ||= Random.new
      @random.bytes(nbytes).unpack('h*').first
    end

    def directory
      File.dirname(filename)
    end

    def load_token
      return false unless File.file?(filename)
      JSON.parse(File.read(filename)) rescue false
    end

    def token_born
      File.mtime(filename)
    end

    def token_age
      Time.now - token_born
    end
  end
end
