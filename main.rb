require 'net/http'
require 'uri'

RAW_SOURCE_URL = "https://www.reddit.com/r/wallpapers/top/.json?sort=top&t=day"
WALLPAPER_DIR = File.expand_path "~/wallpaper"
LOG_PATH = File.expand_path "~/wallpaper/wallpapers.log"

TOO_MANY_REQUESTS_TIMEOUT = 10 # seconds

NOTIFICATION_TIME = 9 # seconds
NOTIFICATION_NAME = "Wallpapers"

# -----------------------

def get_source(url)
    loop do
        src = Net::HTTP.get(URI.parse(url))
        return src unless src[13, 17] == "Too Many Requests"
        sleep TOO_MANY_REQUESTS_TIMEOUT
    end
end

def get_wallpaper_info(src)
    m = src.match /"permalink": "(?<permalink>[^"]+)".+?"url": "(?<url>[^"]+)"/
    { permalink: "https://www.reddit.com" + unescape(m[:permalink]), url: unescape(m[:url]) }
end

def unescape(s)
    eval %Q{"#{s}"} # such vulerability, wow
end

def get_image_url(url)
    case url
    when /imgur\.com\/\w+$/
        unescape get_source(url).match(/"image_src"\s+href="(?<url>[^"]+)"/)[:url]
    when /imgur\.com\/a\/(?<id>\w+)$/
        unescape(get_source("https://api.imgur.com/3/album/#{$~[:id]}") \
        .scan(/"link":"(?<link>[^"]+)"/) \
        .drop(1).sample.first)
    else
        url
    end
end

def make_safe(path)
    "'#{path}'" # the quote has to be ' because the changer script uses "
end

def changer_command(wallpaper_path)
    changer_script = %Q~

    allDesktops = desktops();
    for (i = 0; i < allDesktops.length; ++i)
    {
        d = allDesktops[i];
        d.wallpaperPlugin = "org.kde.image";
        d.currentConfigGroup = Array("Wallpaper", "org.kde.image", "General");
        d.writeConfig("Image", "file://#{wallpaper_path}")
    }

    ~
    
    "qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript #{make_safe changer_script}"
end

def log(text)
    open(LOG_PATH, 'a') { |log| log.puts "[#{`date`.strip}] #{text}" }
end

def notification_command(text)
    "notify-send -t #{NOTIFICATION_TIME * 1000} -a #{make_safe NOTIFICATION_NAME} #{make_safe text}"
end

def get_old_path
    Dir[File.join WALLPAPER_DIR, '*'].select { |entry| File.basename(entry).match /\d\.\w+/ }.first
end

def get_new_path(old_path, image_url)
    name = old_path.nil? ? "1" : (File.basename(old_path)[0].to_i % 2 + 1).to_s
    File.join WALLPAPER_DIR, "#{name}.#{image_url.split('.')[-1]}"
end

def main
    wallpaper_info = get_wallpaper_info get_source(RAW_SOURCE_URL)
    image_url = get_image_url wallpaper_info[:url]
    
    old_path = get_old_path
    new_path = get_new_path old_path, image_url
    temp_path = make_safe `mktemp`.strip
    
    `wget -q -O #{temp_path} #{image_url}`
    `rm -f #{make_safe old_path}` unless old_path.nil?
    `mv #{temp_path} #{make_safe new_path}`
    `#{changer_command new_path}`
    `#{notification_command "Wallpaper changed"}`
    
    log wallpaper_info[:permalink] + " " + image_url
rescue
    log "ERROR:\n" \
        "#{$!.class} - #{$!}\n" \
        "backtrace: #{$!.backtrace.join "\n\t"}\n" \
        "wallpaper_info: #{wallpaper_info.inspect}\n" \
        "image_url: #{image_url.inspect}"
    
    system notification_command("Encountered an error! See log at #{LOG_PATH}")
end

main