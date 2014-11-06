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

    @base_url = if @host =~ /^https?:\/\//
                  @host
                else
                  "http://" + @host
                end

    fail "The server at #{@host} does not provide the\
      correct API version. v2 is required." unless api_compatible?
  end

  def api_url(path = '')
    "/cider-ci/api/v2/#{path}"
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
      get(api_url)
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
      data = JSON.parse(get(data['_links']['next']['href']))
      tasks = recurse_tasks(tasks, data)
    end
    tasks
  end

  def tasks
    tasks = []
    recurse_tasks(tasks,
                  JSON.parse(get(execution_url('tasks'))))
  end

  # I've got a long thing, what can I say...
  # rubocop:disable Metrics/MethodLength
  def trials
    trials = []
    tasks.each do |task|
      task_url = task['href']
      details = JSON.parse(get(task_url))
      trials_url = details['_links']['cici:trials']['href']
      puts "Need to retrieve all trials for #{details['_links']['cici:trials']['href']}"
      single_trial = JSON.parse(get(trials_url))
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
      trial_url = trial['href']
      puts "Retrieving trial details for #{trial_url}."
      single_trial = JSON.parse(get(trial_url))
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
      trial_attachment_url = tag['href']
      trial_attachment_details = JSON.parse(get(trial_attachment_url))
      matching_tas << trial_attachment_details['_links']['cici:trial-attachment'].select do |ta|
        ta if ta['href'].match(pattern)
      end
    end
    matching_tas.flatten.map { |ta| ta['href'] }
  end

  def attachment_data(href)
    attachment_details = JSON.parse(get(href))
    stream_url = attachment_details['_links']['data-stream']['href']
    get(stream_url)
  end


  def get(url)
    full_url = if url =~ /^https?:\/\//
                 url
               else
                 @base_url + url
               end

    RestClient::Request.new(
      method: :get,
      url: full_url,
      user: @username,
      password:  @password
    ).execute
  end

end
