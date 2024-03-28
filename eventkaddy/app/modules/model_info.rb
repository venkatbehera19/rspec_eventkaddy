module ModelInfo

  def self.hash_for_model model
    format("{ %s }", model.columns.map {|s| "#{s.name}: #{s.type}" }.join(', ') )
  end

  # ignores callbacks, but walks the dependent :destroy tree
  # to at least obey has_many and belongs_to destroy definitions. No
  # other callbacks will be obeyed, as the models are not loaded
  # ModelInfo.delete_assoication_records_fast SurveyResponse, :event_id, 20, true
  def self.delete_assoication_records_fast model, key, ids, skip_gets=false
    records = ids_for_all_dependent_destroy_records_for_event(model, key, ids)
    puts records
    puts "Okay to delete these records? [y/n]"
    response = skip_gets ? 'y' : STDIN.gets.chomp
    if response == 'y'
      records.each { |k, v| k.constantize.where(id:v).delete_all }
    else
      puts "No records deleted."
    end
  end

  # a fast version that relies on a bit of complicated logic to get
  # counts for all destroy_callback records related to a model
  # could be asbtracted to take the node trees as an argument, instead
  # of hard coding it to gather the destroy ones, but there's currently
  # no use case for that
  def self.count_all_dependent_destroy_records_for_event model, key, ids
    result = Hash.new 0 # all values start as 0

    model_ids = model.where( key => ids ).pluck(:id)

    result[ model.name.snakecase.to_sym ] = model_ids.length

    count_records_for_nodes = ->( node, key, ids, parent_model ) {
      case node[:macro]
      when :has_many, :has_one
        klass = class_for( node[:class_name] )
        foreign_ids = klass.where(node[:foreign_key] => ids).pluck(:id)

        result[ node[:association].to_s.singularize.to_sym ] += foreign_ids.length

        node[:children].each do |child|
          count_records_for_nodes[ child, child[:foreign_key], foreign_ids, klass ]
        end

      when :belongs_to
        child_foreign_ids = parent_model.where( id: ids ).pluck( node[:foreign_key] )

        result[ node[:association].to_s.singularize.to_sym ] +=
          class_for( node[:class_name] ).
          where(id: child_foreign_ids).
          pluck(:id).
          length

        node[:children].each do |child|
          count_records_for_nodes[ child, child[:foreign_key], foreign_ids, klass ]
        end
      else
        raise "Association type #{assoc} was not defined by delete_all_and_associated_records."
      end
    }

    dependent_destroy_associations_for(model).each do |node|
      count_records_for_nodes[ node, node[:foreign_key], model_ids, model ]
    end

    result
  end

  def self.dependent_destroy_associations_for model, found=[]
    # this -> name -> constant only for the sake of
    # recursion, since we receive association.name as symbol

    # either a real active record model, or the result of reflect on
    # associations. reflect offers class_name, which is more accurate than
    # name (name can be anything when defined in belongs_to). model does
    # not have a class_name method by default, but the name will always be
    # accurate
    klass = model.respond_to?(:class_name) ? model.class_name.constantize
                                           : model.name.constantize

    klass.reflect_on_all_associations.select {|a|
      a.options[:dependent] == :destroy
    }.map{|a|
      unless found.include? a.name
        found << a.name
        { 
          association: a.name,
          class_name:  a.class_name,
          foreign_key: a.foreign_key.to_sym,
          macro:       a.macro,
          children:    dependent_destroy_associations_for(a, found).flatten
        }
      else
        # returning this array actually give nested array, in the case
        # of nested relationships; I've chosen to use flatten as a quick
        # workaround
        []
      end
    }
  end

  def self.count_of_each_association instance
    count_association = ->( instance, assoc, found=[] ) {
      unless found.include? assoc[:association]
        # prevent circular references
        found << assoc[:association]

        # also, there is obviously some refactoring possible here, but
        # I probably will end up leaving it alone. It will be easy enough
        # if I want to do it later, since there are tests backing this code up

        if instance.is_a? Array
          instance.map do |i|
            # deal with return of model, nil, or array of models
            children = [i.send( assoc[:association] )].flatten.compact
            {
              association: assoc[ :association ],
              count:       children.length,
              children: assoc[:children].map {|a| 
                # we need to use clone here, or we will not only 
                # prevent circular references, but we'll erroneously
                # stop siblings from looking for their children
                count_association[children, a, found.clone] 
              }.flatten
            }
          end
        else
          children = [instance.send( assoc[:association] )].flatten.compact || []
          {
            association: assoc[ :association ],
            count:       children.length,
            children: assoc[:children].map {|a| 
              count_association[children, a, found.clone] 
            }.flatten # flatten in the case instance.send returns array
          }
        end
      else
        []
      end
    }
    dependent_destroy_associations_for(instance.class).map do |a|
      count_association[ instance, a ]
    end
  end

  def self.sum_count_of_each_association instance
    # sum is a rails method; otherwise you would use map reduce pattern
    flatten_association_tree(
      count_of_each_association(instance)
    ).sum {|a| a[:count] }
  end

  # this is probably too slow; and to be fast I would have to spend
  # even more time developing the query.
  #
  # Annoyingly, when we destroy_all we're going to be loading all these models
  # anyway, but we don't have a good way for accessing them for our count.
  # def self.sum_count_of_associations_for_model_by_event_id model, event_id
  #   model.where(event_id: event_id).map {|m|
  #     sum_count_of_each_association m
  #   }.sum
  # end

  private

  # For each node
  # check if it has children
  # if it does, check each of those children
  # recursion
  # always add self to array
  #
  # This could probably be made slightly more elegant and avoid
  # the state variable, but it works and it's good enough
  def self.flatten_association_tree ary_of_trees, child_key=:children
    result = []

    add_children_to_result = ->( children ) {
      children.each do |child|
        unless child[ child_key ].blank?
          add_children_to_result[ child[ child_key ] ]
        end
        result << child.except( child_key )
      end
    }

    add_children_to_result[ ary_of_trees ]
    result
  end

  def self.class_for symbol
    symbol.to_s.singularize.classify.constantize
  end

  def self.ids_for_all_dependent_destroy_records_for_event model, key, ids
    # all values start as []
    # You can't use Hash.new [] here, because otherwise all keys
    # will have a reference to the same array, and cause very confusing
    # behaviour
    result = Hash.new {|hash, key| hash[key] = [] }

    model_ids = model.where( key => ids ).pluck(:id)

    result[ model.name ].concat( model_ids )

    count_records_for_nodes = ->( node, key, ids, parent_model ) {
      case node[:macro]
      when :has_many, :has_one
        klass = class_for( node[:class_name] )
        foreign_ids = klass.where(node[:foreign_key] => ids).pluck(:id)

        result[ node[:class_name] ].concat( foreign_ids )

        node[:children].each do |child|
          count_records_for_nodes[ child, child[:foreign_key], foreign_ids, klass ]
        end

      when :belongs_to
        child_foreign_ids = parent_model.where( id: ids ).pluck( node[:foreign_key] )

        result[ node[:class_name] ].concat(
          class_for( node[:class_name] ).where(id: child_foreign_ids).pluck(:id)
        )

        node[:children].each do |child|
          count_records_for_nodes[ child, child[:foreign_key], foreign_ids, klass ]
        end
      else
        raise "Association type #{assoc} was not defined by delete_all_and_associated_records."
      end
    }

    dependent_destroy_associations_for(model).each do |node|
      count_records_for_nodes[ node, node[:foreign_key], model_ids, model ]
    end

    result
  end
end

# ModelInfo.ids_for_all_dependent_destroy_records_for_event Speaker, :event_id, 118
