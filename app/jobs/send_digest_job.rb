class SendDigestJob < ApplicationJob
  queue_as :default

  def perform
    Rails.application.load_tasks
    Rake::Task["send_digest"].reenable
    Rake::Task["send_digest"].invoke
  end
end
