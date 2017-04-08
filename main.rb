require 'open-uri'

RAW_SOURCE_URL = "https://www.reddit.com/r/wallpapers/top/.json?sort=top&t=day"
WALLPAPER_PATH = File.expand_path "~/wallpaper/wallpaper"
LOG_PATH = File.expand_path "~/wallpaper/wallpapers.log"

NOTIFICATION_TIME = 9 # seconds
NOTIFICATION_NAME = "Wallpapers"

# -----------------------

def get_source(url)
    open(url, &:read)
end

def get_wallpaper_info(source)
    source.match /\"permalink\": \"(?<permalink>[^\"]+)\".+?\"url\": \"(?<url>[^\"]+)\"/
end

def get_image_url(url)
    url.match(/imgur\.com\/\w+$/) ? get_source(url).match(/"image_src"\s+href="(?<url>[^"]+)"/)[:url] : url
end

def make_safe(path)
    "'#{path}'" # the quote has to be ' because the changer script uses "
end

def add_image_extension(path, image_url)
    "#{path}.#{image_url.split('.')[-1]}"
end

def changer_command(wallpaper_path)
    changer_script =
    "
    allDesktops = desktops();
    for (i = 0; i < allDesktops.length; ++i)
    {
        d = allDesktops[i];
        d.wallpaperPlugin = \"org.kde.image\";
        d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");
        d.writeConfig(\"Image\", \"file://#{wallpaper_path}\")
    }
    "
    
    "qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript #{make_safe changer_script}"
end

def run(commands)
    system commands.join(" && ")
end

def log(text)
    open(LOG_PATH, 'a') { |log| log.puts "[#{`date`.strip}] #{text}" }
end

def notification_command(text)
    "notify-send -t #{NOTIFICATION_TIME * 1000} -a #{make_safe NOTIFICATION_NAME} #{make_safe text}"
end

def main
    wallpaper_info = get_wallpaper_info get_source(RAW_SOURCE_URL)
    image_url = get_image_url wallpaper_info[:url]

    wallpaper_path = add_image_extension WALLPAPER_PATH, image_url
    old_path = make_safe(WALLPAPER_PATH + '.') + '*'
    temp_path = make_safe `mktemp`.strip

    run \
    ([
        "wget -q -O #{temp_path} #{image_url}",
        "rm -f #{old_path}",
        "mv #{temp_path} #{make_safe wallpaper_path}",
        changer_command(wallpaper_path),
        notification_command("Wallpaper changed")
    ])
    
    log wallpaper_info[:permalink]
rescue => e
    log "#{e.class}: #{e.message} at #{__FILE__}:#{__LINE__}\n" \
        "wallpaper_info: #{wallpaper_info.inspect}\n" \
        "image_url: #{image_url.inspect}"
    
    system notification_command('Encountered an error! See log at #{LOG_PATH}')
end

main