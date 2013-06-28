require "driveregator/version"
require 'google/api_client'
require 'launchy'
require 'yaml'

class Hash
  def deep_stringify_keys
    new_hash = {}
    self.each do |key, value|
      new_hash.merge!(key.to_s => (value.is_a?(Hash) ? value.deep_stringify_keys : value))
    end
  end
end

module Driveregator

  class Yamler
    def self.write(filename, hash)
      File.open(filename, "w") do |f|
        f.write(yaml(hash))
      end
    end

    def self.yaml(hash)
      hash.deep_stringify_keys.to_yaml.
                              gsub("!ruby/symbol ", ":").
                              sub("---","").
                              split("\n").map(&:rstrip).join("\n").strip
    end
  end

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
      return @files unless @files.nil?

      @files =  {}.tap do |ret|
                  @client.execute(:api_method => @drive.files.list).
                  data.to_hash['items'].map do |hsh|
                    ret[hsh['id']] =
                    { 'id'          => hsh['id'],
                      'title'       => hsh['title'],
                      'link'        => hsh['alternateLink'],
                      'parent_ids'  => parent_ids(hsh['id']) }
                  end
                end
    end

    def parent_ids(file_id)
      @files[file_id]['parent_ids'] rescue
      @client.execute(:api_method => @drive.parents.list,
                      :parameters => { 'fileId' => file_id }).
                      data['items'].map(&:id)
    end

    def parent(file_id)
      files[parent_ids(file_id).first]
    end

    def parent_titles(file_id)
      parents = []
      file_parent = parent file_id
      while !file_parent.nil?
        parents.unshift file_parent['title']
        file_parent = parent file_parent['id']
      end

      parents
    end

    def permissions_for_file(file_id)
      @permissions[file_id] ||= {}.tap do |ret|
                                  @client.execute(:api_method => @drive.permissions.list,
                                                  :parameters => { 'fileId' => file_id }).
                                          data.to_hash['items'].map do |hsh|
                                            ret[(hsh['name'] || hsh['id'])] = hsh['role']
                                          end
                                end
    end



    def permissions_by_files
      perm = {}
      files.each do |file_id, file_info|
        title = file_info['title']
        perm[title]                   = {}
        perm[title]['link']           = file_info['link']
        if file_parent = parent(file_id)
          perm[title]['parent_link']  = file_parent['link']
          perm[title]['drive_path']   = parent_titles(file_id).join('/')
        end
        perm[title]['permissions']    = permissions_for_file(file_id)
      end

      perm
    end

    def permissions_by_users
      perm = {}
      permissions_by_files.each do |filename, perm_hsh|
        perm_hsh['permissions'].each do |user, role|
          perm[user] ||= {}
          perm[user][filename] = {}
          perm[user][filename]['link'] = perm_hsh['link']
          perm[user][filename]['parent_link'] = perm_hsh['parent_link'] if perm_hsh['parent_link']
          perm[user][filename]['drive_path']  = perm_hsh['drive_path'] if perm_hsh['drive_path']

          perm[user][filename]['role'] = role
        end
      end

      perm
    end

    def report_by_users
      Yamler::write "users_report_#{Time.now.strftime('%Y_%m_%d_%H:%M:%S')}.yml", permissions_by_users
    end

    def report_by_files
      Yamler::write "files_report_#{Time.now.strftime('%Y_%m_%d_%H:%M:%S')}.yml", permissions_by_files
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
