class CategoryLink < ActiveRecord::Base
  belongs_to :category 
  belongs_to :categorizable , :polymorphic => true 

  # validates_presence_of :category
  # validates_presence_of :categorizable
end
