#############################################################
# Package: Olympus Prepare IOS Icon Images Script
#
#  Script: prepare_ios_images
#
#   Create iOS icons from a base 1024x1024
#	image file and copy images into the public/event_data/#{event_id}/res
#   folder
#############################################################

require 'fileutils'

module AppImageScripts
  class CreateIosIcons
    include Magick

    def create_ios_icons event_id
      puts "Inside CreateIosIconsClass, Started at #{Time.now.utc.strftime("%H:%M:%S")}".green
      event_file_type = EventFileType.find_by(name: "ios_app_icon_img")
      event_file_name = EventFile.find_by(event_id: event_id, event_file_type_id: event_file_type.id).path.split("/").last
      base_image_url  = Rails.root.join('event_app_form_data', event_id.to_s,'uploaded_images','ios','ios_app_icon',event_file_name).to_path
      res_icons_dir   = Rails.root.join('event_app_form_data', event_id.to_s,'transformed_images',"icon","ios_icons").to_path

      unless File.directory?(res_icons_dir)
        FileUtils.mkdir_p(res_icons_dir)
      end
      # delete if new picture is uploaded and the job is started again.
      FileUtils.rm_rf("#{Dir[res_icons_dir]}/*")

      #create icons of various sizes from base image
      img_specs = [
        "icon.png:57", #iphone/ipod touch
        "icon@2x.png:114", 
        "icon-72.png:72", #ipad
        "icon-72-2x.png:144",
        "icon-72@2x.png:144",
        "icon-20.png:20",
        "icon-small.png:29", #iphone spotlight and settings icon
        "icon-small@2x.png:58",
        "icon-small@3x.png:87",
        "icon-57-2x.png:114",
        "icon-57@2x.png:114",
        "icon-57.png:57",
       "icon-51@2x.png:101",
        "icon-50.png:50", #ipad spotlight and settings icon
        "icon-50@2x.png:100", 
        "icon-40.png:40", #iOS 6.1 spotlight icon
        "icon-40@2x.png:80",
        "icon-60.png:60", #iOS 7 iPhone
        "icon-60@2x.png:120",
        "icon-76.png:76", #iOS 7 iPad
        "icon-76@2x.png:152",
        "icon-83.5.png:83.5",
        "icon-83.5@2x.png:167",
        "icon-60@3x.png:180", #iOS 8+ iPhone
        "icon-27.5@2x.png:55",
        "icon-27.5@2x.png:55",
"icon-24@2x.png:48",
"icon-33@2x.png:66",
"icon-44@2x.png:88",
"icon-46@2x.png:92",
"icon-86@2x.png:172",
"icon-98@2x.png:196",
"icon-108@2x.png:216",
"icon-117@2x.png:234",
        "icon-1024.png:1024"
      ]

      img_specs.each do |spec|

        #read in fresh copy of the base image
        base_image = Magick::Image::read(base_image_url).first

        filename = spec.split(":")[0]
        resize_x = spec.split(":")[1]
        resize_y = resize_x
        aspect_ratio = nil

        #resize
        base_image.change_geometry("#{resize_x}x#{resize_y}#{aspect_ratio}") { |cols, rows, img|  img.resize!(cols,rows) }

        #save new image
        base_image.write("#{res_icons_dir}/#{filename}")

        puts "Image written:#{res_icons_dir}/#{filename}".light_yellow
      end

      puts "Finished work inside CreateIosIconsClass, Ended at #{Time.now.utc.strftime("%H:%M:%S")}".green
    end
  end
end
