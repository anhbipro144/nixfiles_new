{ buildNpmPackage, lib, nodejs_24 }:

buildNpmPackage {
  pname = "moodle-cli";
  version = "0.9.6";
  src = builtins.fetchGit {
    url = "ssh://git@github.com-personal/anhbipro144/moodle-dttt.git";
    rev = "a130dd4b237ffbd56df764cddf4d2c8b753b0f7c";
  };
  nodejs = nodejs_24;
  npmDepsHash = "sha256-2j5YtR7jf9mnoCNvAqOISE5799Hegk/mrxCdj7rb+UI=";

  meta = {
    description = "Moodle command line client for students and AI agents";
    homepage = "https://github.com/anhbipro144/moodle-dttt";
    license = lib.licenses.mit;
    mainProgram = "moodle";
    platforms = lib.platforms.unix;
  };
}
