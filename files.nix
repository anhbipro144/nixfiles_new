{ pkgs, lib, ... }:
let
  passWithOtp = pkgs.pass.withExtensions (exts: [ exts.pass-otp ]);
  qutePassPython = pkgs.python3.withPackages (ps: [ ps.tldextract ]);
  quteTranslatePopupPython = pkgs.python3.withPackages (ps: [ ps.requests ]);
  quteTranslateInputRuntimePath = lib.makeBinPath [ pkgs.rofi ];
  qutePassRuntimePath = lib.makeBinPath [
    passWithOtp
    pkgs.gnupg
    pkgs.rofi
  ];
in {

  home.file = {
    ".config/kitty/themes".source = ./kitty/themes;
    ".config/nvim" = {
      source = ./nvim;
      recursive = true;
    };

    ".config/qutebrowser/config.py".source = ./qutebrowser/config.py;

    ".local/share/qutebrowser/userscripts/qute-pass" = {
      executable = true;
      text = ''
        #!${qutePassPython}/bin/python3
        import os
        import runpy

        os.environ["PATH"] = "${qutePassRuntimePath}:" + os.environ.get("PATH", "")
        runpy.run_path(
            "${pkgs.qutebrowser}/share/qutebrowser/userscripts/qute-pass",
            run_name="__main__",
        )
      '';
    };

    ".local/share/qutebrowser/userscripts/translate-popup" = {
      executable = true;
      text = ''
        #!${quteTranslatePopupPython}/bin/python3
        import argparse
        import json
        import os
        import sys
        import urllib.parse

        import requests


        def js(message):
            return f"""
            (function() {{
                var box = document.createElement('div');
                box.style.position = 'fixed';
                box.style.bottom = '10px';
                box.style.right = '10px';
                box.style.backgroundColor = 'white';
                box.style.color = 'black';
                box.style.borderRadius = '8px';
                box.style.padding = '10px';
                box.style.boxShadow = '0 2px 10px rgba(0,0,0,0.2)';
                box.style.zIndex = '10000';
                box.innerText = decodeURIComponent("{message}");
                document.body.appendChild(box);

                function removeBox(event) {{
                    if (!box.contains(event.target)) {{
                        box.remove();
                        document.removeEventListener('click', removeBox);
                    }}
                }}
                document.addEventListener('click', removeBox);
            }})();
            """


        def translate_google(text, target_lang):
            encoded_text = urllib.parse.quote(text)
            response = requests.get(
                "https://translate.googleapis.com/translate_a/single"
                f"?client=gtx&sl=auto&tl={target_lang}&dt=t&q={encoded_text}"
            )
            response_json = json.loads(response.text)
            translated_text = ""
            for item in response_json[0]:
                translated_text += item[0]
            return translated_text


        def translate_libretranslate(text, url, key, target_lang):
            response = requests.post(
                f"{url}/translate",
                data={
                    "q": text,
                    "source": "auto",
                    "target": target_lang,
                    "api_key": key,
                },
            )
            return response.json()["translatedText"]


        def main():
            parser = argparse.ArgumentParser(
                description="Translate text using different providers."
            )
            parser.add_argument(
                "--provider",
                choices=["google", "libretranslate"],
                required=False,
                default="google",
                help="Translation provider to use",
            )
            parser.add_argument(
                "--libretranslate_url",
                required=False,
                default="https://libretranslate.com",
                help="URL for LibreTranslate API",
            )
            parser.add_argument(
                "--libretranslate_key",
                required=False,
                default="",
                help="API key for LibreTranslate",
            )
            parser.add_argument(
                "--target_lang",
                required=False,
                default="en",
                help="Target language for translation",
            )
            parser.add_argument(
                "--url",
                action="store_true",
                help="Translate the current URL instead of selected text",
            )
            args = parser.parse_args()

            qute_fifo = os.getenv("QUTE_FIFO")
            if not qute_fifo:
                sys.stderr.write(
                    f"Error: {sys.argv[0]} can not be run as a standalone script.\n"
                )
                sys.stderr.write(
                    "It is a qutebrowser userscript. Call it with 'spawn --userscript'.\n"
                )
                sys.exit(1)

            if args.url:
                current_url = urllib.parse.quote(os.getenv("QUTE_URL", ""))
                translated_url = (
                    "https://translate.google.com/translate?"
                    f"sl=auto&tl={args.target_lang}&u={urllib.parse.quote(current_url)}"
                )
                with open(qute_fifo, "a") as fifo:
                    fifo.write(f"open -t {translated_url}\n")
                return

            text = os.getenv("QUTE_SELECTED_TEXT", "")
            if args.provider == "google":
                translated_text = translate_google(text, args.target_lang)
            elif args.provider == "libretranslate":
                translated_text = translate_libretranslate(
                    text,
                    args.libretranslate_url,
                    args.libretranslate_key,
                    args.target_lang,
                )

            js_code = js(urllib.parse.quote(translated_text)).replace("\n", " ")
            with open(qute_fifo, "a") as fifo:
                fifo.write(f"jseval -q {js_code}\n")


        if __name__ == "__main__":
            main()
      '';
    };

    ".local/share/qutebrowser/userscripts/translate-input-popup" = {
      executable = true;
      text = ''
        #!${quteTranslatePopupPython}/bin/python3
        import argparse
        import json
        import os
        import subprocess
        import sys
        import urllib.parse

        import requests


        os.environ["PATH"] = "${quteTranslateInputRuntimePath}:" + os.environ.get(
            "PATH", ""
        )


        def popup_js(source_text, translated_text):
            source_json = json.dumps(source_text)
            translated_json = json.dumps(translated_text)
            return f"""
            (function() {{
                var oldBox = document.getElementById('qute-translate-input-popup');
                if (oldBox) {{
                    oldBox.remove();
                }}

                var box = document.createElement('div');
                box.id = 'qute-translate-input-popup';
                box.style.position = 'fixed';
                box.style.bottom = '16px';
                box.style.right = '16px';
                box.style.maxWidth = '420px';
                box.style.padding = '12px 14px';
                box.style.background = '#ffffff';
                box.style.color = '#111111';
                box.style.border = '1px solid rgba(0,0,0,0.14)';
                box.style.borderRadius = '8px';
                box.style.boxShadow = '0 8px 24px rgba(0,0,0,0.22)';
                box.style.zIndex = '2147483647';
                box.style.font = '14px/1.45 sans-serif';
                box.style.whiteSpace = 'pre-wrap';

                var source = document.createElement('div');
                source.style.opacity = '0.7';
                source.style.marginBottom = '8px';
                source.textContent = {source_json};

                var result = document.createElement('div');
                result.style.fontWeight = '600';
                result.textContent = {translated_json};

                box.appendChild(source);
                box.appendChild(result);
                document.body.appendChild(box);

                function removeBox(event) {{
                    if (!box.contains(event.target)) {{
                        box.remove();
                        document.removeEventListener('click', removeBox);
                    }}
                }}

                setTimeout(function() {{
                    document.addEventListener('click', removeBox);
                }}, 0);
            }})();
            """


        def translate_google(text, target_lang):
            response = requests.get(
                "https://translate.googleapis.com/translate_a/single",
                params={
                    "client": "gtx",
                    "sl": "auto",
                    "tl": target_lang,
                    "dt": "t",
                    "q": text,
                },
                timeout=15,
            )
            response.raise_for_status()
            response_json = response.json()
            return "".join(item[0] for item in response_json[0])


        def read_input(prompt):
            result = subprocess.run(
                ["rofi", "-dmenu", "-p", prompt, "-lines", "0"],
                input="",
                text=True,
                capture_output=True,
                check=False,
            )
            if result.returncode != 0:
                return ""
            return result.stdout.strip()


        def main():
            parser = argparse.ArgumentParser(
                description="Prompt for text and translate it in qutebrowser."
            )
            parser.add_argument(
                "--target_lang",
                required=False,
                default="en",
                help="Target language for translation",
            )
            parser.add_argument(
                "--prompt",
                required=False,
                default="Translate",
                help="Input prompt label",
            )
            args = parser.parse_args()

            qute_fifo = os.getenv("QUTE_FIFO")
            if not qute_fifo:
                sys.stderr.write(
                    f"Error: {sys.argv[0]} can not be run as a standalone script.\n"
                )
                sys.stderr.write(
                    "It is a qutebrowser userscript. Call it with 'spawn --userscript'.\n"
                )
                sys.exit(1)

            text = read_input(args.prompt)
            if not text:
                return

            translated_text = translate_google(text, args.target_lang)
            js_code = popup_js(text, translated_text).replace("\n", " ")
            with open(qute_fifo, "a") as fifo:
                fifo.write(f"jseval -q {js_code}\n")


        if __name__ == "__main__":
            main()
      '';
    };

    ".config/macchina" = { source = ./macchina; };
    ".config/jiratui" = { source = ./jiratui; };
  };

}
