class Location < ActiveRecord::Base
  include Comparable

  acts_as_nested_set

  extend FriendlyId
  friendly_id :name, :use => :slugged

  validates :name, :presence => true
  has_many :products

  has_one :photo, :as => :photoable
  accepts_nested_attributes_for :photo, :allow_destroy => true

  has_one :seo_settings, :as => :seo_settingsable
  accepts_nested_attributes_for :seo_settings, :allow_destroy => true, :reject_if => proc { |attrs| attrs.any? { |key, value| value.blank? } }

  has_many :suggestions

  scope :alphabetical_order , :order => 'name ASC'

  scope :child_locations, lambda { |slug|
    parent = Location.current_location_slug slug
    parent_id = Location.select(:id).where("slug = ?", parent).first
    condition = parent_id ? parent_id.id : nil
    where :parent_id => condition
  }

  scope :nested, :order => "lft ASC"

  has_one :gallery_link , :as => :galleryable
  has_one :gallery , :through => :gallery_link

  def <=>(another)
    self.name <=> another.name &&
    self.slug <=> another.slug
  end

  # Thinking sphinx index
  define_index do
    indexes :name, :sortable => true

    has products.category_links(:category_id), :as => :product_category_ids, :facet => true
  end

  def self.current_location_slug slug
    location_slugs = slug.split('/')
    location_slugs.size > 0 ? location_slugs.last : slug
  end

  def self.find_by_slug slug
    Location.where(:slug => Location.current_location_slug(slug)).first
  end

  def self.find_by_category slug, root_with_descendants = false, category_ids = []
    if slug.is_a? String
      category = Category.select('id').find(slug)
      category_ids << category.id
    end

    locations = Product.search(:with_all => {:category_ids => category_ids}, :group_by => 'location_id', :group_function => :attr, :per_page => 1000).collect {|p| p.location}

    if root_with_descendants
      locations = organize_by_root_with_descendants(locations)
    end
    locations
  end

  def self.find_locations_for_packages slug
    category_id = slug
    if slug.is_a? String
      category = Category.select('id').find(slug)
      category_id = category.id
    end
    locations = Location.joins('JOIN packages ON packages.location_id = locations.id').where('packages.category_id = ?', category_id).uniq
    self.organize_by_root_with_descendants(locations)
  end

  def self.organize_by_root_with_descendants locations
    output = Hash.new
    until locations.empty? do
      current_location = locations.pop

      Location.roots.each do |location|
        if !current_location.nil? && current_location.is_descendant_of?(location)
          output[location] = output[location].nil? ? [current_location] : output[location] << current_location
        end
      end
    end
    output
  end

  def short_description
    if description
      length = 400
      s = self.description.slice(0..length)
      s << "..." if self.description.length > length
      s
    end
  end
end
