#!/bin/sh
echo
dot_mt="$HOME/.minetest"
if [ ! -d "$dot_mt" ]; then
  echo "ERROR: Nothing done since no $dot_mt."
  exit 1
fi
MT_MYGAME_MODS_PATH="$dot_mt/mods"
MTMOD_DEST_NAME="nether"
MTMOD_DEST_PATH="$MT_MYGAME_MODS_PATH/$MTMOD_DEST_NAME"
flag_file="$MTMOD_DEST_PATH/init.lua"
end_msg="Successfully installed to $MTMOD_DEST_PATH"
if [ ! -d "$MTMOD_DEST_PATH" ]; then
  mkdir -p "$MTMOD_DEST_PATH"
fi
if [ ! -f init.lua ]; then
  cd "${0%/*}"
  echo "WARNING: had to change directory to `pwd` since init.lua was not found..."
fi

if [ ! -f init.lua ]; then
  echo "You are not in the nether mod, so install.sh failed."
  exit 2
fi
cp -R * "$MTMOD_DEST_PATH"
if [ ! -f "$flag_file" ]; then
  end_msg="$MTMOD_DEST_PATH could not be installed ($flag_file not copied to destination)."
fi
echo "$end_msg"
echo
echo
