class DashboardController < ApplicationController
  def index
    articles = params[:show_all] ? Article.where(ai_filtered: true) : Article.relevant
    articles = articles.order(published_at: :desc, score: :desc)
    articles = filter_by_language(articles)
    @articles_by_week = articles.group_by { |a| a.published_at.to_date.beginning_of_week }
  end

  private

  def filter_by_language(scope)
    return scope if Current.user.lang_both?

    if Current.user.lang_tr?
      scope.where.not(summary_tr: [ nil, "" ])
    else
      scope.where.not(summary_en: [ nil, "" ])
    end
  end
end
