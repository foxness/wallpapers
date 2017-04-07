require 'open-uri'

RAW_SOURCE_URL = "https://www.reddit.com/r/wallpapers/top/.json?sort=top&t=day"
SLIDESHOW_DIR = File.expand_path "~/wallpaper"
SLIDESHOW_DELAY = 60 # seconds

# -----------------------

current_wallpaper = Dir.glob(File.join SLIDESHOW_DIR, '*') \
                    .map { |path| File.basename path }
                    .select { |name| name[1] == '.' } \
                    .first

fail 'no current wallpaper found' if current_wallpaper.nil?

wallpapers = open(RAW_SOURCE_URL, &:read).scan /\"permalink\": \"(?<permalink>[^\"]+)\".+?\"url\": \"(?<url>[^\"]+)\"/
url = wallpapers[0][1]

tick = current_wallpaper.nil? ? '2' : current_wallpaper[0]
tock = (tick.to_i % 2 + 1).to_s

pathify = lambda { |path| "\"#{File.join SLIDESHOW_DIR, path}\"" }

temp = pathify['tmp']
new_wallpaper = pathify["#{tock}.#{url.split('.')[-1]}"]
current_wallpaper = pathify[current_wallpaper]

cmds = "wget -q -O #{temp} #{url} " \
    "&& mv #{temp} #{new_wallpaper} " \
    "&& sleep #{SLIDESHOW_DELAY + 3} " \
    "&& rm -f #{current_wallpaper}"

`#{cmds}`