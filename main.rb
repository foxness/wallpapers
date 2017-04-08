require 'open-uri'

RAW_SOURCE_URL = "https://www.reddit.com/r/wallpapers/top/.json?sort=top&t=day"
WALLPAPER_PATH = File.expand_path "~/wallpaper/wallpaper"

# -----------------------

wallpapers = open(RAW_SOURCE_URL, &:read).scan /\"permalink\": \"(?<permalink>[^\"]+)\".+?\"url\": \"(?<url>[^\"]+)\"/
url = wallpapers[0][1]

path = "#{WALLPAPER_PATH}.#{url.split('.')[-1]}"

changer_script =
"
allDesktops = desktops();
for (i = 0; i < allDesktops.length; ++i)
{
    d = allDesktops[i];
    d.wallpaperPlugin = \"org.kde.image\";
    d.currentConfigGroup = Array(\"Wallpaper\", \"org.kde.image\", \"General\");
    d.writeConfig(\"Image\", \"file://#{path}\")
}
"

make_safe = lambda { |path| "'#{path}'" } # the quote has to be ' because the changer script uses "

changer_command = "qdbus org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript #{make_safe[changer_script]}";

temp = make_safe[`mktemp`.strip]
old_path = make_safe[WALLPAPER_PATH + '.'] + '*'

system("wget -q -O #{temp} #{url} " \
    "&& rm -f #{old_path} " \
    "&& mv #{temp} #{make_safe[path]} " \
    "&& #{changer_command}")