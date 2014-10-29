require 'webmock'
require 'webmock/rspec'
require 'json'

ROOT_URL = 'user:pass@cider.example.org'
BASE_URL = 'user:pass@cider.example.org/cider-ci/api/v1'

def response_file(path)
  File.open(File.expand_path("responses/#{path}", File.dirname(__FILE__)))
end

def trials_dir_exists_for_task?(task)
  Dir.exist?(File.expand_path("responses/task/#{task}/trials", File.dirname(__FILE__)))
end

def basic_stubs
    stub_request(:get,
                 "#{BASE_URL}/execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6").
      to_return(:body => response_file('execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/index.json'),
                :status => 200,
                :headers => { 'Content-type' => 'application/json' })

    stub_request(:get,
                 "#{BASE_URL}/execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks").
      to_return(:body => response_file('execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks/index.json'),
                :status => 200,
                :headers => { 'Content-type' => 'application/json' })

    stub_request(:get,
                 "#{BASE_URL}/execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks").
      with(:query => {:page => 1}).
      to_return(:body => response_file('execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks/page_1.json'),
                :status => 200,
                :headers => { 'Content-type' => 'application/json' })

    stub_request(:get,
                 "#{BASE_URL}/execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks").
      with(:query => {:page => 2}).
      to_return(:body => response_file('execution/f7c80b61-1ed5-43ee-a9cd-11a2fc2d5db6/tasks/page_2.json'),
                :status => 200,
                :headers => { 'Content-type' => 'application/json' })


    tasks = ['08abffb3-ee8e-403b-949a-0e95e6a78ac0', '4c0d5916-2e2a-4caf-aa79-b6df54652614',
             '5892453f-8555-4c1b-894c-e1cb70891f1c', 'ce4bd431-e193-4333-a0d5-61332fe3ed5d',
             'f8e1d8f5-3bda-4229-a23c-e817bd7a0fa3', '08ea6e2b-0501-4246-bb39-44202c9ead97']

    tasks.each do |task|
      # First, mock the task itself
      stub_request(:get,
                   "#{BASE_URL}/task/#{task}").
        to_return(:body => response_file("task/#{task}.json"),
                  :status => 200,
                  :headers => { 'Content-type' => 'application/json' })

      # Then mock any trials present for this task
      mock_trials_for_task(task)
    end
end



# TODO refactor all these mocks to read their self URL from the JSON
# file and set themselves up at that location. But what about page?

def self_href_from_file(path)
  JSON.parse(File.read(path))[0]['_links']['self']['href']
end

def mock_trial_attachment(path)
  self_url = "#{ROOT_URL}#{self_href_from_file(path)}"
  stub_request(:get,
               self_url).
   to_return(:body => path,
            :status => 200,
            :headers => { 'Content-type' => 'application/json' })
end

def mock_trial_attachments(trial)
  stub_request(:get,
               "#{BASE_URL}/trial/#{trial}/trial-attachments").
   to_return(:body => response_file("trial/#{trial}/trial-attachments/index.json"),
            :status => 200,
            :headers => { 'Content-type' => 'application/json' })
end

def mock_trial(trial)
  stub_request(:get,
               "#{BASE_URL}/trial/#{trial}").
   to_return(:body => response_file("trial/#{trial}.json"),
            :status => 200,
            :headers => { 'Content-type' => 'application/json' })
   mock_trial_attachments(trial)
end


# Loads the index.json and page_n.json files from a specific task's trials subdir,
# then sets up the matching mocks.
def mock_trials_for_task(task)
  if trials_dir_exists_for_task?(task)
    trials_dir = File.expand_path("responses/task/#{task}/trials", File.dirname(__FILE__))
    Dir.glob(File.join(trials_dir, "*.json")) do |path|
      if File.basename(path) =~ /^page/
        page_number = File.basename(path).match(/^page\_(\d)\.json/)[1]
        stub_request(:get,
                     "#{BASE_URL}/task/#{task}/trials").
          with(:query => {:page => page_number}).
          to_return(:body => File.open(path),
                    :status => 200,
                    :headers => { 'Content-type' => 'application/json' })
      else
        # Only index.json should end up here
        stub_request(:get,
                     "#{BASE_URL}/task/#{task}/trials").
          to_return(:body => File.open(path),
                    :status => 200,
                    :headers => { 'Content-type' => 'application/json' })
      end
      trial_hrefs = JSON.parse(File.read(path))['_links']['cici:trial'].map{|trial| trial['href']}
      trial_hrefs.each do |th|
        trial_id = th.split("/").last
        mock_trial(trial_id)
      end
    end
  else
    return 0
  end
end
