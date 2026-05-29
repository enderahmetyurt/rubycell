class FetchArticlesJob < ApplicationJob
  queue_as :default

  def perform
    Rails.application.load_tasks
    Rake::Task["articles:fetch"].reenable
    Rake::Task["articles:fetch"].invoke
    AiSummarizeJob.perform_later
  end
end
