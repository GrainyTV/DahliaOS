# Clone Hyprland repository
# Find tagged version used by the system
git clone https://github.com/hyprwm/Hyprland.git --recursive hyprland
cd hyprland
hyprctl version | grep Tag | awk '{system("git checkout tags/" $2)}'
git submodule update

# Store the applied commit's creation date for future use
date=$( git rev-parse HEAD | git log --no-patch --no-notes --pretty="%cd" --date=short -1 )

# Generate protocol files used for plugin compilation
# Then we exit from here
make all -j$( nproc )
cd ..

# Clone titlebars plugin
# The rest is unnecessary
mkdir hyprland-plugins
cd hyprland-plugins
git init
git remote add -f origin https://github.com/hyprwm/hyprland-plugins.git
git config core.sparseCheckout true
echo "hyprbars" >> .git/info/sparse-checkout
git pull origin main

# Find first commit that works on our release build of Hyprland
# We use the previously queried date here
commit=$( git log --pretty=format:"%H" --no-patch --no-notes --reverse --since=$date -1 )
git reset --hard $commit
cd hyprbars

# Modify plugin directory
# Remove Hyprland from pkgconf
includeLineIndex=$( grep -n "INCLUDES =" Makefile | awk -F  ":" '{print $1}' )
sed -i "${includeLineIndex}s| hyprland||" Makefile
sed -i "1s|$| -I.|" Makefile

# Make use of local files instead of fallback ones
# Copy src, wlr folders, protocol, version and config files
mkdir hyprland
cp ./../../hyprland/src/ ./hyprland/src/ -r
cp ./../../hyprland/subprojects/wlroots/include/wlr/ . -r
cp ./../../hyprland/protocols/*.h .
cp ./../../hyprland/subprojects/wlroots/build/include/wlr/version.h ./wlr/version.h
cp ./../../hyprland/subprojects/wlroots/build/include/wlr/config.h ./wlr/config.h

# Finally compile plugin
# Then clean unnecessary files and folders
make all -j$( nproc )
mv ./hyprbars.so ./../../hyprbars.so
cd ./../..
rm ./hyprland -rf
rm ./hyprland-plugins -rf