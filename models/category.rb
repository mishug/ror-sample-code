class Category < ActiveRecord::Base
  include Comparable

  acts_as_nested_set
  extend FriendlyId
  friendly_id :nested_slug_name  , :use => :slugged

  validates_presence_of :name

  has_many :category_links

  SUITABILITIES = %w[hen stag corporate]

  def <=>(another)
    self.name <=> another.name &&
    self.slug <=> another.slug
  end

  def nested_slug_name
    self.parent ? "#{parent.name} #{name}" : name
  end

  def self.all_ids_for(category)
    if category.root?
      category.descendants.collect{|d|d.id}.push(category.id)
    else
      [category.id]
    end
  end

  def self.get_categories_with_products category_conditions = [], product_conditions = {}
    categories_with_products = Hash.new

    Category.roots.each do |r|
      next if Category.suitability? r

      categories_with_products[r] = []
      r.children.each do |c|
        product_conditions[:category_ids] = category_conditions + [c.id]
        categories_with_products[r] << c if (Product.search_count(:with_all => product_conditions) > 0)
      end
      # only keep the root if it has children or products
      if categories_with_products[r].empty?
        product_conditions[:category_ids] = category_conditions + [r.id]
        categories_with_products.delete(r) if (Product.search_count(:with_all => product_conditions) == 0)
      end
    end

    categories_with_products
  end

  def self.identify_suitability string
    suitability = nil

    Category::SUITABILITIES.each do |s|
      suitability = s if string.include?(s)
      break unless suitability.nil?
    end

    suitability
  end

  def self.suitability? verify
    Category::SUITABILITIES.include? verify.name.downcase
  end
end
