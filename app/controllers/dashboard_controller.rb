class DashboardController < ApplicationController
  def index
    articles = Article.relevant.order(score: :desc, published_at: :desc)
    articles = filter_by_language(articles)
    @pagy, @articles = pagy(articles, limit: 20)
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
