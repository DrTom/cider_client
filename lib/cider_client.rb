require 'rest-client'
require 'json'
require 'fileutils'

# Allows you to query a Cider CI server using Ruby. Wraps the responses
# in Ruby data structures (usually hashes)
class CiderClient
  attr_accessor :execution_id, :host
  attr_writer :username, :password

  def initialize(options = {})
    @host = options.fetch(:host)
    @username = options.fetch(:username)
    @password = options.fetch(:password)
    fail "The server at #{@host} does not provide the\
      correct API version. v2 is required." unless api_compatible?
  end

  # Returns the base URL including usernames and passwords. Always uses usernames
  # and passwords, because you can't do anything on Cider without basic auth anyhow.
  # Is used in all further url_* methods.
  def base_url
    "http://#{@username}:#{@password}@#{@host}"
  end

  # URL starting from the base URL root, with the passed path appended
  def url(path)
    "#{base_url}#{path}"
  end

  def api_url(path = '')
    url("/cider-ci/api/v2/#{path}")
  end

  # URL starting from the execution, with the passed path appended
  # TODO: Stick these *_url methods into something like url_for(:execution, 'foo')
  def execution_url(path)
    api_url("execution/#{@execution_id}/#{path}")
  end

  def api_compatible?
    begin
      # Try to get the API root URL. If it 404s out, this server probably
      # doesn't offer that API version.
      RestClient.get(api_url)
      api_version_matches = true
    rescue RestClient::ResourceNotFound
      api_version_matches = false
    end
    api_version_matches
  end

  def recurse_tasks(tasks, data)
    if data['_links']['cici:task']
      tasks = tasks.concat(data['_links']['cici:task'])
    end
    if data['_links']['next']
      puts "Retrieved #{tasks.count} tasks total so far."
      data = JSON.parse(RestClient.get(url(data['_links']['next']['href'])))
      tasks = recurse_tasks(tasks, data)
    end
    tasks
  end

  def tasks
    tasks = []
    recurse_tasks(tasks,
                  JSON.parse(RestClient.get(execution_url('tasks'))))
  end

  # I've got a long thing, what can I say...
  # rubocop:disable Metrics/MethodLength
  def trials
    trials = []
    tasks.each do |task|
      task_url = url(task['href'])
      details = JSON.parse(RestClient.get(task_url))
      trials_url = url(details['_links']['cici:trials']['href'])
      puts "Need to retrieve all trials for #{details['_links']['cici:trials']['href']}"
      single_trial = JSON.parse(RestClient.get(trials_url))
      single_trial['_links']['cici:trial'].each do |st|
        trials << st
      end
    end
    trials
  end

  # Misguided idea: We thought we could retrieve all attachments
  # based on a commit SHA traced to its tree id, but you do need
  # an execution ID
  # def tree_id_from_commit(commit_sha)
  #   `git show #{commit_sha} --format=%T | head -1`.chomp
  # end

  def trial_attachment_groups
    puts 'Retrieving trial details to find all attachments, this may take a long time.'
    trial_attachment_groups = []
    trials.each do |trial|
      trial_url = url(trial['href'])
      puts "Retrieving trial details for #{trial_url}."
      single_trial = JSON.parse(RestClient.get(trial_url))
      trial_attachment_groups << \
        single_trial['_links']['cici:trial-attachments']
    end
    trial_attachment_groups
  end

  # Takes a regex pattern and returns only hrefs of the attachments
  # that matched the regex.
  def trial_attachment_hrefs(pattern = /.*/)
    matching_tas = []
    trial_attachment_groups.each do |tag|
      trial_attachment_url = url(tag['href'])
      trial_attachment_details = JSON.parse(RestClient.get(trial_attachment_url))
      matching_tas << trial_attachment_details['_links']['cici:trial-attachment'].select do |ta|
        ta if ta['href'].match(pattern)
      end
    end
    matching_tas.flatten.map { |ta| ta['href'] }
  end

  def attachment_data(href)
    attachment_details = JSON.parse(RestClient.get(url(href)))
    stream_url = attachment_details['_links']['data-stream']['href']

    # Stupid fix because the CI hosts seem to return their own IP instead of hostname
    # in these responses
    stream_url.gsub!('https://195.176.254.43', base_url)
    RestClient.get(stream_url)
  end
end
