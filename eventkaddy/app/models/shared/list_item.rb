module ListItem

  def createAndUpdatePositions(json, new_item)
    json = JSON.parse(json)
    json.each do |item|
    	if (item["id"]==="new")
    		new_item.position = item["order"].to_i
        new_item.save!
    	else
    		self.where(id:item["id"].to_i).first.update_column(:position, item["order"].to_i)
    	end
    end
  end

  def updatePositions(json)
    json = JSON.parse(json)
    json.each do |item|
      record = self.where(id:item["id"].to_i).first
      record.update_column(:position, item["order"].to_i) unless record.blank?
    end
  end

  def updatePositionsAndDisable(list_items)
    list_items_to_change = list_items.where("position > ? ", self.position)
    list_items_to_change.each do |item|
      item.update_column(:position, item.position-1)
    end
    self.update_columns(enabled:false, position:nil)
  end

  def updatePositionsAndDestroy(list_items)
    list_items_to_change = list_items.where("position > ? ", self.position)
    list_items_to_change.each do |item|
      item.update_column(:position, item.position-1)
    end
    self.destroy
  end

end