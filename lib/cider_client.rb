require 'rest-client'
require 'json'
require 'fileutils'

class CiderClient
  attr_accessor :execution_id, :commit_sha, :cider_host
  attr_writer :username, :password

  @execution_id = nil
  @commit_sha = nil
  @username = nil
  @password = nil
  @cider_host = nil

  def mode
    if @execution_id and not @commit_sha
      mode = "execution_id"
    elsif @commit_sha and not @execution_id
      mode = "commit_sha"
    end
    mode
  end

  def base_url
    return "http://#{@username}:#{@password}@#{@cider_host}"
  end

  # URL starting from the base URL root, with the passed path appended
  def url(path)
    return "#{base_url}/#{path}"
  end

  def api_url(path)
    return url("/cider-ci/api/v1/#{path}")
  end

  # URL starting from the execution, with the passed path appended
  def execution_url(path)
    return api_url("execution/#{@execution_id}/#{path}")
  end

  def recurse_tasks(tasks, data)
    if data["_links"]["cici:task"]
      tasks = tasks.concat(data["_links"]["cici:task"])
    end
    if data["_links"]["next"]
      puts "Retrieved #{tasks.count} tasks total so far."
      data = JSON.parse(RestClient.get(url(data["_links"]["next"]["href"])))
      tasks = recurse_tasks(tasks, data)
    end
    tasks
  end

  def tasks
    tasks = []
    tasks = recurse_tasks(tasks, JSON.parse(RestClient.get(execution_url("tasks"))))
  end

  def trials
    trials = []
    tasks.each do |task|
      task_url = url(task['href'])
      details = JSON.parse(RestClient.get(task_url))
      trials_url = url(details["_links"]["cici:trials"]["href"])
      puts "Need to retrieve all trials for #{details["_links"]["cici:trials"]["href"]}"
      single_trial = JSON.parse(RestClient.get(trials_url))
      single_trial["_links"]["cici:trial"].each do |st|
        trials << st
      end
    end
    trials
  end

  def tree_id_from_commit(commit_sha)
    `git show #{commit_sha} --format=%T | head -1`.chomp
  end

  def tree_attachment_hrefs(pattern = /.*/)
    raise "This is still broken. Don't try."
    tree_id = tree_id_from_commit(self.commit_sha)
    matching_tas = []
    tree_attachments = JSON.parse(RestClient.get(api_url("tree-attachments/#{tree_id}")))
    binding.pry

    matching_tas << tree_attachment_details["_links"]["cici:tree-attachment"].select {|ta|
      ta if ta["href"].match(pattern)
    }
    matching_tas.flatten.map {|ta|
      ta["href"]
    }
  end

  def trial_attachment_groups
    puts "Retrieving trial details to find all attachments, this may take a long time."
    trial_attachment_groups = []
    trials.each do |trial|
      trial_url = url(trial["href"])
      puts "Retrieving trial details for #{trial_url}."
      single_trial = JSON.parse(RestClient.get(trial_url))
      trial_attachment_groups << single_trial["_links"]["cici:trial-attachments"]
    end
    trial_attachment_groups
  end

  # Takes a regex pattern and returns only hrefs of the attachments that matched the regex.
  def trial_attachment_hrefs(pattern = /.*/)
    matching_tas = []
    trial_attachment_groups.each do |ta|
      trial_attachment_url = url(ta["href"])
      trial_attachment_details = JSON.parse(RestClient.get(trial_attachment_url))
      matching_tas << trial_attachment_details["_links"]["cici:trial-attachment"].select {|ta|
        ta if ta["href"].match(pattern)
      }
    end
    matching_tas.flatten.map {|ta|
      ta["href"]
    }
  end

  def attachment_data(href)
    attachment_details = JSON.parse(RestClient.get(url(href)))
    stream_url = attachment_details["_links"]["data-stream"]["href"]
    stream_url.gsub!("https://195.176.254.43", base_url) # Stupid fix because the CI hosts seem to return their own IP instead of hostname in these responses
    RestClient.get(stream_url)
  end
end
