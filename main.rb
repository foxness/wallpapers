require 'open-uri'

RAW_SOURCE_URL = "https://www.reddit.com/r/wallpapers/top/.json?sort=top&t=day"
WALLPAPER_PATH = File.expand_path "~/wallpaper/wallpaper"

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

def get_changer_command(wallpaper_path)
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
    system(commands.join " && ")
end

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
    get_changer_command(wallpaper_path)
])