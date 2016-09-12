# class used to exclude or include category options from Awesome Nested Set helper nested_set_options
class CategoryMover
  include ApplicationHelper

  def initialize suitability_condition
      @suitability_condition = suitability_condition
   end

  def new_record?
    false
  end

  def move_possible?(i)
    @suitability_condition == "party_type" ? suitability_category?(i) : !suitability_category?(i)
  end

  class << self
    @@party_type = CategoryMover.new "party_type"
    @@category = CategoryMover.new "category"

    private :new

    def category
      @@category
    end

    def party_type
      @@party_type
    end
  end
end
