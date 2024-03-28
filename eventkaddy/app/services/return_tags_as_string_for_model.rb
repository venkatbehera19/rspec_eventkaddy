class ReturnTagsAsStringForModel

  def initialize(args)
    @model           = args[:model]
    @tag_type        = TagType.where(name:args[:tag_type]).first
    @assoc_model     = "Tags#{@model.class.name}".constantize
    @assoc_column    = "#{@model.class.name.downcase}_id".to_sym
    @tag_groups      = []
    @tag_delimiter   = '||'
    @group_delimiter = '^^'
  end

  def call
    return_string
  end

  def return_string

      #find all the existing tag groups
      assoc_tags = @assoc_model
        .select("#{@assoc_column}, tag_id, tags.parent_id AS tag_parent_id, tags.name AS tag_name")
        .joins("JOIN tags ON #{@assoc_model.name.underscore}s.tag_id=tags.id")
        .where("#{@assoc_column}=? AND tags.tag_type_id=?", @model.id, @tag_type.id)

      assoc_tags.each do |assoc_tag|
        ary = []
        ary << assoc_tag.tag_name
        parent_id = assoc_tag.tag_parent_id

        #add ancestor tags, if any
        while parent_id!=0
          tag = Tag.where(id:parent_id)
          if tag.length==1
            ary << tag[0].name
            parent_id = tag[0].parent_id
          else
            parent_id = 0
          end
        end
        @tag_groups << ary.reverse #reverse the order, as we followed the tag tree from leaf to root
      end
      @tag_groups.map {|g| g.join @tag_delimiter }.join @group_delimiter
  end

end
