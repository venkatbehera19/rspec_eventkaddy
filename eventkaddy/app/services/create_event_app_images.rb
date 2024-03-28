class CreateEventAppImages
  include Magick

  ANDROID_ICON_SPECS = [
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

  IOS_ICON_SPECS = [
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
    "icon-57.png:57",
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
    "icon-44@2x.png:88", 
    "icon-24@2x.png:48", 
    "icon-27.5@2x.png:55", 
    "icon-86@2x.png:172", 
    "icon-98@2x.png:196", 
    "icon-108@2x.png:216", 
    "icon-117@2x.png:234", 
    "icon-33@2x.png:66", 
    "icon-44@2x.png:88", 
    "icon-46@2x.png:92", 
    "icon-51@2x.png:102", 
    "icon-1024.png:1024"
  ]


  def initialize(args)
    @form             =  args[:app_form]
    @base_image_path  =  args[:base_image_path]
  end

  def call
    create_app_images
  end

  private
  
  attr_reader :form,:base_image_path


  def ensure_path
    FileUtils.mkdir_p(target_path) unless File.directory?(target_path)
  end


  def create_app_images
    ensure_path
  end

end
