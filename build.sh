CURRENT_DIRECTORY="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
NAME_PART=NppLsp

PROJECT=NppLspClient
VEXE=v

ARCH=x64
CC=clang

# build resources
RC="$CURRENT_DIRECTORY/$NAME_PART.rc"
if [ -f "$RC" ]; then
  RES_OBJ=(-cflags "\"$CURRENT_DIRECTORY/$NAME_PART.res\"")
else
  RES_OBJ=()
fi

NPPPATH="$CURRENT_DIRECTORY/out/$ARCH"
PLUGIN_DIR="$NPPPATH/plugins/$PROJECT"

mkdir -p "$PLUGIN_DIR"
# if [ ! -d "$PLUGIN_DIR" ]; then
#   echo "$PLUGIN_DIR does not exist."
#   exit
# fi

PLUGIN_PATH="$PLUGIN_DIR/$PROJECT.dll"
echo $PLUGIN_PATH

COMPILER_FLAGS=(-g -d static_boehm -gc boehm -keepc -enable-globals -shared -d no_backtrace)

if [ "$ARCH" = x64 ]; then
  COMPILER_FLAGS+=()
else
  COMPILER_FLAGS+=(-m32)
fi

windres "$RC" -O coff -o "$CURRENT_DIRECTORY/$NAME_PART.res"
echo "$VEXE" -cc "$CC" "${COMPILER_FLAGS[@]}" -cflags "\"-I$CURRENT_DIRECTORY\"" "${RES_OBJ[@]}" -o "$PLUGIN_PATH" .
"$VEXE" -cc "$CC" "${COMPILER_FLAGS[@]}" -cflags "\"-I$CURRENT_DIRECTORY\"" "${RES_OBJ[@]}" -o "$PLUGIN_PATH" .
