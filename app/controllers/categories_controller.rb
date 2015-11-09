class CategoriesController < ApplicationController
  def index

    @categories = Category.all
  end

  def show
    @category = Category.find(params[:id])
    @loan_requests = @category.loan_requests.page(params[:page]).order('created_at DESC')
  end
end
