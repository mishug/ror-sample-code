class Product < ActiveRecord::Base

  extend FriendlyId
  friendly_id :name_in_location , :use => :slugged

  validates :name , :presence => true
  validates :description , :presence => true
  validates :price_cents , :presence => true
  validates :price_currency , :presence => true

  validates :supplier , :presence => true
  validates :location , :presence => true
  validates :categories , :presence => true

  has_one  :overriding_address, :as => :addressable , :class_name => 'Address'
  accepts_nested_attributes_for :overriding_address , :reject_if => :all_blank

  belongs_to :supplier
  belongs_to :location

  has_one :photo, :as => :photoable
  accepts_nested_attributes_for :photo, :allow_destroy => true , :reject_if =>:all_blank

  belongs_to :package

  has_many :category_links , :as => :categorizable
  accepts_nested_attributes_for :category_links , :reject_if => :all_blank
  has_many :categories , :through => :category_links

  has_one :gallery_link , :as => :galleryable
  accepts_nested_attributes_for :gallery_link ,:reject_if => :all_blank
  has_one :gallery , :through => :gallery_link

  has_many :messages , :as => :messagable

  has_one :seo_settings, :as => :seo_settingsable
  accepts_nested_attributes_for :seo_settings, :allow_destroy => true, 
    :reject_if => proc {|attrs| attrs.all? {|key, value| value.blank?}}

  # Thinking sphinx index
  define_index do
    indexes :name
    indexes description
    indexes full_description
    indexes package(:name), :as => :package
    indexes location(:name), :as => :location
    indexes overriding_address.country(:name), :as => :country

    has location(:id), :as => :location_id
    has categories(:id), :as => :category_ids
    has minimum_group_size, maximum_group_size, price_cents
  end

  composed_of :price,
    :class_name => "Money",
    :mapping => [%w(price_cents cents), %w(price_currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  composed_of :cost_price,
    :class_name => "Money",
    :mapping => [%w(cost_price_cents cents), %w(cost_price_currency currency_as_string)],
    :constructor => Proc.new { |cents, currency| Money.new(cents || 0, currency || Money.default_currency) },
    :converter => Proc.new { |value| value.respond_to?(:to_money) ? value.to_money : raise(ArgumentError, "Can't convert #{value.class} to Money") }

  def address
    overriding_address.blank? ? supplier.address : overriding_address
  end

  def category_names
    names = ""
    categories.each_with_index do |c, x|
      names << " / " unless x == 0
      names << c.name
    end
    names
  end

  def name_in_location
    "#{name} in #{location.name}"
  end
end
