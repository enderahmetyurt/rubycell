class AiSummarizeJob < ApplicationJob
  queue_as :default

  def perform
    Rails.application.load_tasks
    Rake::Task["articles:ai_summarize"].reenable
    Rake::Task["articles:ai_summarize"].invoke
  end
end
