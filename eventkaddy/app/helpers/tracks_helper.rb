module TracksHelper

	def html_color_picker(name)
	     #build the hexes
		hexes = []
		(0..15).step(3) do |one|
		 (0..15).step(3) do |two|
		   (0..15).step(3) do |three|
		    hexes << "#" + one.to_s(16) + two.to_s(16) + three.to_s(16)
		   end
		 end
		end
	     arr = []
	     on_change_function = "onChange=\"document.getElementById('color_div').style.backgroundColor = this[this.selectedIndex].value\""
	     10.times { arr << "&nbsp;" }
	       returning html = '' do
	      html << "<div id=\"color_div\" style=\"border:1px solid black;z-index:100;position:absolute;width:30px\"> &nbsp; </div> "
	      html << "<select name=#{name}[color] id=#{name}_color #{on_change_function}>"
	      html << hexes.collect {|c|
	        "<option value='#{c}' style='background-color: #{c}'>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</option>" }.join("\n")
	      html << "</select>"
	    end
	end

	def jquery_color_picker(name)
		
=begin		
		hexes = []
		(0..15).step(3) do |one|
		 (0..15).step(3) do |two|
		   (0..15).step(3) do |three|
		    hexes << one.to_s(16) + two.to_s(16) + three.to_s(16)
		   end
		 end
		end
=end
		hexes = []
		hexes[0]='B7A9D4'
		hexes[1]='7EC5F7'
		hexes[2]='BBF77E'	
		hexes[3]='F7F57E'
		hexes[4]='F7C97E'
		hexes[5]='F0FAB9'
		    
	    returning html = '' do
	 
	      html << "<select name=#{name} id=\"track-color-picker\">"
	      html << hexes.collect {|c|
	        "<option value='#{c}'>#{c}</option>" }.join("\n")
	        #"<option value='#{c}' style='background-color:#{c}'>#{c}</option>" }.join("\n")
	      html << "</select>"
	    end

	end
	

end
