#############################################################
# Package: Olympus Prepare Android Icon Script
#
#  Script: prepare_ios_images
#
#   Create Android icons from a base 1024x1024
# image file and copy images into the cordova_project/res
# folder
#############################################################

require 'fileutils'

module AppImageScripts
  class CreateAndroidIcons
    include Magick

    def create_android_icons event_id
      puts "Inside CreateAndroidIconsClass, Started at #{Time.now.utc.strftime("%H:%M:%S")}".green
      event_file_type = EventFileType.find_by(name: "android_app_icon_img")
      event_file_name = EventFile.find_by(event_id: event_id, event_file_type_id: event_file_type.id).path.split("/").last
      base_image_url  = Rails.root.join('event_app_form_data', event_id.to_s,'uploaded_images','android','android_app_icon',event_file_name).to_path
      res_icons_dir    = Rails.root.join('event_app_form_data', event_id.to_s,'transformed_images',"icon","android_icons").to_path

      xml_string = Nokogiri::XML("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<adaptive-icon xmlns:android=\"http://schemas.android.com/apk/res/android\">\n    <background android:drawable=\"@mipmap/ic_launcher_background\"/>\n    <foreground android:drawable=\"@mipmap/ic_launcher_foreground\"/>\n</adaptive-icon>\n").to_xml

      unless File.directory?(res_icons_dir)
        FileUtils.mkdir_p(res_icons_dir)
      end

      # delete if new picture is uploaded and the job is started again.
      FileUtils.rm_rf("#{Dir[res_icons_dir]}/*")

      #create icons of various sizes from base image
      img_specs = [
        "mipmap-ldpi:ic_launcher.png:36",
        "mipmap-mdpi:ic_launcher.png:48",
        "mipmap-hdpi:ic_launcher.png:72",
        "mipmap-xhdpi:ic_launcher.png:96",
        "mipmap-xxhdpi:ic_launcher.png:144",
        "store-512:ic_launcher.png:512",
        "store-1024:ic_launcher.png:1024",
        "mipmap-xxxhdpi:ic_launcher.png:192",
        "mipmap-ldpi-v26:ic_launcher_foreground.png:36",
        "mipmap-mdpi-v26:ic_launcher_foreground.png:48",
        "mipmap-hdpi-v26:ic_launcher_foreground.png:72",
        "mipmap-xhdpi-v26:ic_launcher_foreground.png:216",
        "mipmap-xxhdpi-v26:ic_launcher_foreground.png:324",
        "mipmap-xxxhdpi-v26:ic_launcher_foreground.png:432",
        "mipmap-ldpi-v26:ic_launcher_background.png:36",
        "mipmap-mdpi-v26:ic_launcher_background.png:48",
        "mipmap-hdpi-v26:ic_launcher_background.png:72",
        "mipmap-xhdpi-v26:ic_launcher_background.png:216",
        "mipmap-xxhdpi-v26:ic_launcher_background.png:324",
        "mipmap-xxxhdpi-v26:ic_launcher_background.png:432"

      ]

      folders_with_xml_file = [
        "mipmap-mdpi-v26",
        "mipmap-xhdpi-v26",
        "mipmap-ldpi-v26",
        "mipmap-hdpi-v26",
        "mipmap-xxhdpi-v26",
        "mipmap-xxxhdpi-v26"
      ]

      img_specs.each do |spec|
        #read in fresh copy of the base image
        base_image = Magick::Image::read(base_image_url).first
        custom_dir = spec.split(":")[0]
        filename = spec.split(":")[1]
        resize_x = spec.split(":")[2]
        resize_y = resize_x
        aspect_ratio = nil

        #resize
        base_image.change_geometry("#{resize_x}x#{resize_y}#{aspect_ratio}") { |cols, rows, img|  img.resize!(cols,rows) }
        
        #save new image
        FileUtils.mkdir_p("#{res_icons_dir}/#{custom_dir}") unless File.directory?("#{res_icons_dir}/#{custom_dir}")
        base_image.write("#{res_icons_dir}/#{custom_dir}/#{filename}")

        # xml file to be added inside folders of android
        if folders_with_xml_file.include?(custom_dir)
          File.open("#{res_icons_dir}/#{custom_dir}/ic_launcher.xml", "w+", 0777) do |file|
            file.write(xml_string)
          end
        end
        puts "Image written:#{res_icons_dir}/#{custom_dir}/#{filename}".light_yellow
      end
      puts "Finished work inside CreateAndroidIconsClass, Completed at #{Time.now.utc.strftime("%H:%M:%S")}".green
    end
  end
end
