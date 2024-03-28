class DeviceType < ApplicationRecord
 #attr_accessible :id, :leaf, :name, :parent_id

  has_many :app_images

  has_many :device_app_image_sizes

  has_many :app_image_sizes, :through => :device_app_image_sizes

  def self.info
    all.map do |device|
      {
        id: device.id,
        leaf: device.leaf,
        device_name: device.name,
        app_image_sizes: device.app_image_sizes.map {|s|
          {
            id: s.id,
            width: s.image_width,
            height: s.image_height,
            type: s.device_app_image_sizes.where(device_type_id: device.id).map {|x|
              x.app_image_type.name
            }
          }
        }
      }
    end
  end

  def self.get_device(id)
    where(id: id).first
  end
  
end

# pp DeviceType.info
 # [{:id=>1, :leaf=>0, :device_name=>"Phone", :app_image_sizes=>[]},
 #  {:id=>2, :leaf=>0, :device_name=>"Tablet", :app_image_sizes=>[]},
 #  {:id=>3, :leaf=>0, :device_name=>"iOS Phone", :app_image_sizes=>[]},
 #  {:id=>4,
 #   :leaf=>1,
 #   :device_name=>"iOS Tablet",
 #   :app_image_sizes=>
 #    [{:id=>4, :width=>1536, :height=>100, :type=>["banner"]},
 #     {:id=>7, :width=>1250, :height=>80, :type=>["center-header"]}]},
 #  {:id=>5, :leaf=>0, :device_name=>"Android Phone", :app_image_sizes=>[]},
 #  {:id=>6, :leaf=>0, :device_name=>"Windows Phone", :app_image_sizes=>[]},
 #  {:id=>7,
 #   :leaf=>1,
 #   :device_name=>"iPhone 4_5",
 #   :app_image_sizes=>
 #    [{:id=>1, :width=>640, :height=>100, :type=>["banner"]},
 #     {:id=>5, :width=>320, :height=>80, :type=>["center-header"]}]},
 #  {:id=>8,
 #   :leaf=>1,
 #   :device_name=>"iPhone 6",
 #   :app_image_sizes=>
 #    [{:id=>3, :width=>750, :height=>100, :type=>["banner"]},
 #     {:id=>5, :width=>320, :height=>80, :type=>["center-header"]}]},
 #  {:id=>9,
 #   :leaf=>1,
 #   :device_name=>"iPhone 6 Plus",
 #   :app_image_sizes=>
 #    [{:id=>2, :width=>1242, :height=>150, :type=>["banner"]},
 #     {:id=>6, :width=>480, :height=>80, :type=>["center-header"]}]},
 #  {:id=>10,
 #   :leaf=>1,
 #   :device_name=>"Mobile Web",
 #   :app_image_sizes=>[{:id=>9, :width=>320, :height=>50, :type=>["banner"]}]},
 #  {:id=>11, :leaf=>1, :device_name=>"Desktop", :app_image_sizes=>[]},
 #  {:id=>12,
 #   :leaf=>1,
 #   :device_name=>"iPhone X",
 #   :app_image_sizes=>
 #    [{:id=>3, :width=>750, :height=>100, :type=>["banner"]},
 #     {:id=>5, :width=>320, :height=>80, :type=>["center-header"]}]}]
