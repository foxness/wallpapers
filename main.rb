require 'open-uri'

RAW_SOURCE_URL = "https://www.reddit.com/r/wallpapers/top/.json?sort=top&t=day"
SLIDESHOW_DIR = "/home/foxness/wallpaper/"

WALLPAPER_FILENAME = "wallpaper"
TEMP_FILENAME = "tmp"

raw = open(RAW_SOURCE_URL, &:read)
wallpapers = raw.scan(/\"permalink\": \"(?<permalink>[^\"]+)\".+?\"url\": \"(?<url>[^\"]+)\"/)

url = wallpapers[0][1]
filename = "#{WALLPAPER_FILENAME}.#{url.split('.')[-1]}"

command = "wget -q -O \"#{SLIDESHOW_DIR}#{TEMP_FILENAME}\" #{url}"\
      " && rm -f \"#{SLIDESHOW_DIR}#{WALLPAPER_FILENAME}.*\""\
      " && mv \"#{SLIDESHOW_DIR}#{TEMP_FILENAME}\" \"#{SLIDESHOW_DIR}#{filename}\""

`#{command}`