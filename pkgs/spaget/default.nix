{ writeShellScriptBin, target ? "world" }:
writeShellScriptBin "spaget" ''
  echo "hello, ${target}!!"
''