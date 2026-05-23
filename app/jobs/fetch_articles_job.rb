class FetchArticlesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.application.load_tasks
    Rake::Task["fetch"].reenable
    Rake::Task["fetch"].invoke
    AiSummarizeJob.perform_later
  end
end
