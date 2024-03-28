module ActsAsHierarchy

  def acts_as_hierarchy
    extend ActsAsHierarchy::SingletonMethods
    include ActsAsHierarchy::InstanceMethods

    has_many :children, class_name: self.to_s, foreign_key: :parent_id
    belongs_to :parent, class_name: self.to_s, foreign_key: :parent_id, optional: true
  end
  module SingletonMethods
  end
  module InstanceMethods
    def ancestor_id_separator 
      "^"
    end

    def all_descendants
      Tag.where("ancestor_ids like '%#{ancestor_id_separator}#{self.id}#{ancestor_id_separator}%'")
    end
  end
end