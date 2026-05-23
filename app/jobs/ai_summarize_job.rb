class AiSummarizeJob < ApplicationJob
  queue_as :default

  def perform
    Rails.application.load_tasks
    Rake::Task["ai_summarize"].reenable
    Rake::Task["ai_summarize"].invoke
  end
end
