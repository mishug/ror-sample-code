class ActivitiesController < ApplicationController
#List activites with search filters
  def index
    can_search = false
    filter_conditions = ["search_key", "party_type_id", "party_type_name", "location_ids", "location_name", "category_ids", "category_name", "group_size", "minimum_price", "maximum_price"]

    params.each_key do |s|
      can_search = filter_conditions.include? s
      break if can_search
    end

    if can_search
      conditions = {}

      unless params[:party_type_name].blank?
        c = Category.find params[:party_type_name]
        params[:party_type_id] = c.id
      end

      unless params[:category_name].blank?
        c = Category.find params[:category_name]
        params[:category_ids] = [c.id]
      end

      unless params[:location_name].blank?
        l = Location.find params[:location_name]
        params[:location_ids] = l.id
      end

      conditions[:location_id] = params[:location_ids] unless params[:location_ids].blank?

      if !params[:category_ids].blank? || !params[:party_type_id].blank?
        category_ids = []
        category_ids += params[:category_ids] unless params[:category_ids].blank?
        unless params[:party_type_id].blank?
          category_ids <<= params[:party_type_id]
          session[:party_type_id] = params[:party_type_id]
        end
        conditions[:category_ids] = category_ids
      end

      conditions[:minimum_group_size] = 0..params[:group_size].to_i unless params[:group_size].blank?
      conditions[:maximum_group_size] = params[:group_size].to_i..500 unless params[:group_size].blank?

      conditions[:price_cents] = params[:minimum_price].to_i*100..params[:maximum_price].to_i*100 if !params[:minimum_price].blank? && !params[:maximum_price].blank?

      @products = Product.search params[:search_key], :with => conditions, :page => params[:page], :per_page => 10
    else
      @products = Product.paginate :page => params[:page], :per_page => 10
    end
  end
#Display activity acccording to party types
  def index_party_type
    @suitability = Category.identify_suitability request.url
    @show_available_categories = true

    if @suitability
      category_conditions = []

      @default_header = "#{@suitability}_default_header"
      @party_type = Category.select('id, name').find @suitability if @suitability
      category_conditions << @party_type.id

      if(params[:category])
        @category = Category.select('id, name, slug').find params[:category]
        category_conditions << @category.id

        if params[:category] == "accommodation"
          @show_available_categories = false
        end
      end

      @products = Product.search :with_all => {:category_ids => category_conditions}, :page => params[:page], :per_page => 10
    end
  end

#Display particular activity
  def show
    @product = Product.find(params[:id])
  end
#Fetch category of activity
  def category
    @category = Category.find params[:category]
    @products =  Product.includes(:categories).where(:categories => {:id => Category.all_ids_for(@category)})
    @products = @products.paginate :page => params[:page]
    render :index
  end
end
