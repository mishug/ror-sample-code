module ApplicationHelper

  def available_categories(type)
    party_type_id = type
    if type.is_a? String
      party_type = Category.select('id').find type
      party_type_id = party_type.id
    end
    categories = Category.get_categories_with_products([party_type_id])
    render(:partial => 'shared/party_type_categories', :locals => {:categories => categories, :type => type})
  end

  def build_new_payment_path(itinerary_id)
    attributes = {:itinerary_id => itinerary_id}
    attributes[:reference] = params[:reference] if params[:reference]
    new_payment_path(attributes)
  end

  def category_locations(type, current_category = nil)
    type = type.downcase
    locations = Location.find_by_category(type, true, current_category.nil? ? [] : [current_category.id])
    render(:partial => 'shared/category_locations', :locals => {:locations => locations, :type => type, :current_category => current_category})
  end

  def check_status(product, package)
    unless package.products.blank?
      return package.products.include? product
    else
      return false
    end
  end

  # Return a description on a per-page basis.
  def description
    base_description = "Pop The Fizz - Stag and Hen Weekends"
    if @description.nil?
      base_description
    else
      @description
    end
  end

  def display_actual_photo model , size
    size.blank? ? image_tag(model.photo.cover_image.url) : image_tag(model.photo.cover_image.thumb(size).url)
  end

  def display_default_photo model, size
    default_files ={:product => 'ImageComingSoon1.jpg' , :package => 'ImageComingSoon1.jpg' ,:location => 'stags-places.png'}
    image = default_files[model.class.name.downcase.intern]
    thumb = Dragonfly[:images].fetch_file(File.join(Rails.root, 'app/assets/images/', image)).thumb(size)
    size.blank? ? image_tag(image) : image_tag(thumb.url)
  end

  def display_photo model , size = ''
    model.photo.blank? || model.photo.cover_image.nil? ?  display_default_photo(model,size ) : display_actual_photo(model,size)
  end

  def display_price item
    if item.class == Money
      item.format :display_free => true, :symbol => false, :no_cents_if_whole => true
    else
      # item.price.dollars.to_i
      item.price.format :display_free => true, :symbol => false, :no_cents_if_whole => true
    end
  end

  def facebook_share url
    "<div class='fb-like' data-href='#{url}' data-send='true' data-layout='button_count' data-width='450' data-show-faces='false'></div>".html_safe
  end

  # Return a keywords on a per-page basis.
  def keywords
    base_keywords = "stag weekend, stag weekends, stag weekend ideas, stag party ideas"
    if @keywords.nil?
      base_keywords
    else
      @keywords
    end
  end

  def recommend text, object
    link_to text, message_recommend_path(object.class.name.downcase, (object.slug? ? object.slug : object.id))
  end

  def request_information text, object, params = {}
    link_to text, message_request_information_path(object.class.name.downcase, (object.slug? ? object.slug : object.id), params)
  end

  def show_options_for_buying
    # @show
    if current_user
      buying_states = current_user.itineraries.map {|i| ["confirmed", "created"].include?(i.state) }
      @show_options_for_buying = buying_states.include?(false)
    end
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, params.merge(:sort => column, :direction => direction, :page => nil), {:class => css_class}
  end

  def suitability_category? category
    Category.suitability? category
  end

  # Return a title on a per-page basis.
  def title
    base_title = "Pop The Fizz"
    if @title.nil?
      base_title << " - Stag and Hen Weekends"
    else
      "#{@title} | #{base_title}"
    end
  end

  def url_for_location url
    case params[:controller]
      when 'suitabilities'
        if @category
          "/#{@parent_category.slug}/location/#{url}/category/#{@category.slug}"
        else
          "/#{@parent_category.slug}/location/#{url}"
        end
      else
        if @category
          "/locations/#{url}/category/#{@category.slug}"
        else
          "/locations/#{url}"
        end
    end
  end

  def url_location
    case  params[:controller]
      when 'activities'
        '/activities'
      when 'locations'
        '/locations/' + (params[:location_id].blank? ? params[:id] :  params[:location_id])
      when 'packages'
        '/packages'
      else
        url = @parent_category ? '/' + @parent_category.name : ''
        unless params[:location].blank?
          url = url + "/location/#{params[:location]}"
        else
        url
        end
      end
  end

  def url_product(product)
    "/activities/#{product.friendly_id}"
  end
end