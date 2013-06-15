require "driveregator/version"
require 'google/api_client'
require 'launchy'

module Driveregator

  class PermissionReporter
    attr_reader :files, :client

    def initialize(client_id, client_secret, tokens = {})
      @config = { :client_id      => client_id,
                  :client_secret  => client_secret,
                  :oauth_scope    => 'https://www.googleapis.com/auth/drive',
                  :redirect_uri   => 'urn:ietf:wg:oauth:2.0:oob',
                  :access_token   => tokens[:access_token],
                  :refresh_token  => tokens[:refresh_token] }

      @permissions = {}

      @client = Google::APIClient.new :application_name => 'driveregator', :application_version => '0.1'
      @drive  = @client.discovered_api('drive', 'v2')

      @client.authorization.client_id     = @config[:client_id]
      @client.authorization.client_secret = @config[:client_secret]
      @client.authorization.scope         = @config[:oauth_scope]
      @client.authorization.redirect_uri  = @config[:redirect_uri]
      @client.authorization.access_token  = @config[:access_token]
      @client.authorization.refresh_token = @config[:refresh_token]

      get_access
    end

    def files
      @files ||=  @client.execute(:api_method => @drive.files.list).
                  data.to_hash['items'].map do |hsh|
                    { :id     => hsh['id'],
                      :title  => hsh['title'],
                      :link   => hsh['alternateLink'] }
                  end
    end

    def permissions_for_file(file_id)
      @permissions[file_id] ||= @client.execute(:api_method => @drive.permissions.list,
                                                :parameters => { 'fileId' => file_id }).
                                        data.to_hash['items'].map do |hsh|
                                          { :name => hsh['name'] || hsh['id'],
                                            :role => hsh['role'],
                                            :type => hsh['type'] }
                                        end
    end

    def permissions
      files.map{ |file| permissions_for_file(file[:id]) }
    end

    private

    def get_access
      unless @config[:access_token] && @config[:refresh_token]
        uri = client.authorization.authorization_uri(:approval_prompt => :auto)
        Launchy.open(uri)
        $stdout.write  "Enter authorization code: "
        @client.authorization.code = gets.chomp
        @config[:access_token] = @client.authorization.access_token
        @config[:refresh_token] = @client.authorization.refresh_token
      end

      @client.authorization.fetch_access_token!
    end
  end
end
