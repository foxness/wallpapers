require 'net/http'
require 'uri'
require 'open-uri'
require 'Win32API'

RAW_SOURCE_URL = "https://www.reddit.com/r/wallpapers/top/.json?sort=top&t=day"
WALLPAPER_DIR = 'L:\Wallpapers'
WALLPAPER_BASENAME = 'wallpaper'
LOG_FILE = 'wallpapers.log'

TOO_MANY_REQUESTS_TIMEOUT = 10 # seconds

# -----------------------

SPI_SETDESKWALLPAPER = 20
SPIF_UPDATEINIFILE = 0x1
SPIF_SENDWININICHANGE = 0x2

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

def download(url)
    s = open(url)
    path = File.join WALLPAPER_DIR, "#{WALLPAPER_BASENAME}.#{url.split('.')[-1]}"
    IO.copy_stream(s, path)
    path
end

def set_wallpaper(path)
    systemParametersInfo = Win32API.new('user32', 'SystemParametersInfo', ['I','I','P','I'], 'I')
    systemParametersInfo.call(SPI_SETDESKWALLPAPER, 0, path, SPIF_UPDATEINIFILE | SPIF_SENDWININICHANGE)
end

def main
    wallpaper_info = get_wallpaper_info get_source(RAW_SOURCE_URL)
    image_url = get_image_url wallpaper_info[:url]
    
    path = download image_url
    set_wallpaper path
end

main