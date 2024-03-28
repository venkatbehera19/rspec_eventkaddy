#############################################################
# Package: Olympus Prepare SPLASH SCREEN Images Script
#
#  Script: prepare_android_splash_screens
#
#   Create Android splash screens from a base image
#	image file and copy images into the public/event_data/#{event_id}/res
#   folder
#############################################################

require 'fileutils'

module AppImageScripts
  class CreateAndroidSplashScreens
    include Magick

    def create_android_splash_screens event_id
      puts "Inside CreateAndroidSplashScreensClass, Started at #{Time.now.utc.strftime("%H:%M:%S")}".green

      event_file_type_portrait = EventFileType.find_by(name: "android_portrait_splash_screen_img")
      event_file_name_portrait = EventFile.find_by(event_id: event_id, event_file_type_id: event_file_type_portrait.id).path.split("/").last
      base_portrait_image_url = Rails.root.join('event_app_form_data', event_id.to_s,'uploaded_images',"android","android_portrait_splash_screen",event_file_name_portrait).to_path

      event_file_type_landscape = EventFileType.find_by(name: "android_landscape_splash_screen_img")
      event_file_name_landscape = EventFile.find_by(event_id: event_id, event_file_type_id: event_file_type_landscape.id).path.split("/").last
      base_landscape_image_url = Rails.root.join("event_app_form_data", event_id.to_s,"uploaded_images","android","android_landscape_splash_screen",event_file_name_landscape).to_path

      res_splash_dir  = Rails.root.join('event_app_form_data', event_id.to_s,'transformed_images',"screen","android_screens").to_path

      unless File.directory?(res_splash_dir)
        FileUtils.mkdir_p(res_splash_dir)
      end

      # delete if new picture is uploaded and the job is started again.
      FileUtils.rm_rf("#{Dir[res_splash_dir]}/*")

      #create icons of various sizes from base image
      portrait_img_specs = [
        "drawable-port-hdpi:screen.png:480:800",
        "drawable-port-ldpi:screen.png:200:300",
        "drawable-port-mdpi:screen.png:320:480",
        "drawable-port-xxhdpi:screen.png:960:1600",
        "drawable-port-xxxhdpi:screen.png:1280:1920",
        "drawable-port-xhdpi:screen.png:720:1280"
      ]

      landscape_img_specs = [
        "drawable-land-hdpi:screen.png:800:480",
        "drawable-land-ldpi:screen.png:320:200",
        "drawable-land-mdpi:screen.png:480:320",
        "drawable-land-xxhdpi:screen.png:1600:900",
        "drawable-land-xxxhdpi:screen.png:1920:1280",
        "drawable-land-xhdpi:screen.png:1280:720"
      ]

      def processImageSpecs(specs,base_image_url,res_splash_dir)
        specs.each do |spec|

          #read in fresh copy of the base image
          base_image = Magick::Image::read(base_image_url).first
          custom_dir = spec.split(":")[0]
          filename = spec.split(":")[1]
          resize_x = spec.split(":")[2]
          resize_y = spec.split(":")[3]
          aspect_ratio = "!"

          #resize
          base_image.change_geometry("#{resize_x}x#{resize_y}#{aspect_ratio}") { |cols, rows, img|  img.resize!(cols,rows) }

          #save new image
          FileUtils.mkdir_p("#{res_splash_dir}/#{custom_dir}") unless File.directory?("#{res_splash_dir}/#{custom_dir}")
          base_image.write("#{res_splash_dir}/#{custom_dir}/#{filename}")

          puts "Image written:#{res_splash_dir}/#{custom_dir}/#{filename}".light_yellow
        end
      end
      processImageSpecs(portrait_img_specs,base_portrait_image_url,res_splash_dir)
      processImageSpecs(landscape_img_specs,base_landscape_image_url,res_splash_dir)

      puts "Finished work inside CreateAndroidSplashScreensClass, Ended at #{Time.now.utc.strftime("%H:%M:%S")}".green
    end
  end
end