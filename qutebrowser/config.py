# Documentation:
#   qute://help/configuring.html
#   qute://help/settings.html

from typing import Any

config: Any = globals()["config"]
c: Any = globals()["c"]

CHROME_DEVTOOLS_URL = "chrome-devtools://*"
DEVTOOLS_URL = "devtools://*"
CONTENT_JAVASCRIPT_ENABLED = "content.javascript.enabled"

# Change the argument to True to still load settings configured via autoconfig.yml
config.load_autoconfig(False)

# Aliases for commands. The keys of the given dictionary are the
# aliases, while the values are the commands they map to.
# Type: Dict
c.aliases = {
    "q": "close",
    "qa": "quit",
    "w": "session-save",
    "wq": "quit --save",
    "wqa": "quit --save",
}

# Which cookies to accept. With QtWebEngine, this setting also controls
# other features with tracking capabilities similar to those of cookies;
# including IndexedDB, DOM storage, filesystem API, service workers, and
# AppCache. Note that with QtWebKit, only `all` and `never` are
# supported as per-domain values. Setting `no-3rdparty` or `no-
# unknown-3rdparty` per-domain on QtWebKit will have the same effect as
# `all`. If this setting is used with URL patterns, the pattern gets
# applied to the origin/first party URL of the page making the request,
# not the request URL. With QtWebEngine 5.15.0+, paths will be stripped
# from URLs, so URL patterns using paths will not match. With
# QtWebEngine 5.15.2+, subdomains are additionally stripped as well, so
# you will typically need to set this setting for `example.com` when the
# cookie is set on `somesubdomain.example.com` for it to work properly.
# To debug issues with this setting, start qutebrowser with `--debug
# --logfilter network --debug-flag log-cookies` which will show all
# cookies being set.
# Type: String
# Valid values:
#   - all: Accept all cookies.
#   - no-3rdparty: Accept cookies from the same origin only. This is known to break some sites, such as GMail.
#   - no-unknown-3rdparty: Accept cookies from the same origin only, unless a cookie is already set for the domain. On QtWebEngine, this is the same as no-3rdparty.
#   - never: Don't accept cookies at all.
config.set("content.cookies.accept", "all", CHROME_DEVTOOLS_URL)

# Which cookies to accept. With QtWebEngine, this setting also controls
# other features with tracking capabilities similar to those of cookies;
# including IndexedDB, DOM storage, filesystem API, service workers, and
# AppCache. Note that with QtWebKit, only `all` and `never` are
# supported as per-domain values. Setting `no-3rdparty` or `no-
# unknown-3rdparty` per-domain on QtWebKit will have the same effect as
# `all`. If this setting is used with URL patterns, the pattern gets
# applied to the origin/first party URL of the page making the request,
# not the request URL. With QtWebEngine 5.15.0+, paths will be stripped
# from URLs, so URL patterns using paths will not match. With
# QtWebEngine 5.15.2+, subdomains are additionally stripped as well, so
# you will typically need to set this setting for `example.com` when the
# cookie is set on `somesubdomain.example.com` for it to work properly.
# To debug issues with this setting, start qutebrowser with `--debug
# --logfilter network --debug-flag log-cookies` which will show all
# cookies being set.
# Type: String
# Valid values:
#   - all: Accept all cookies.
#   - no-3rdparty: Accept cookies from the same origin only. This is known to break some sites, such as GMail.
#   - no-unknown-3rdparty: Accept cookies from the same origin only, unless a cookie is already set for the domain. On QtWebEngine, this is the same as no-3rdparty.
#   - never: Don't accept cookies at all.
config.set("content.cookies.accept", "all", DEVTOOLS_URL)

# Value to send in the `Accept-Language` header. Note that the value
# read from JavaScript is always the global value.
# Type: String
config.set("content.headers.accept_language", "", "https://matchmaker.krunker.io/*")

# User agent to send.  The following placeholders are defined:  *
# `{os_info}`: Something like "X11; Linux x86_64". * `{webkit_version}`:
# The underlying WebKit version (set to a fixed value   with
# QtWebEngine). * `{qt_key}`: "Qt" for QtWebKit, "QtWebEngine" for
# QtWebEngine. * `{qt_version}`: The underlying Qt version. *
# `{upstream_browser_key}`: "Version" for QtWebKit, "Chrome" for
# QtWebEngine. * `{upstream_browser_version}`: The corresponding
# Safari/Chrome version. * `{upstream_browser_version_short}`: The
# corresponding Safari/Chrome   version, but only with its major
# version. * `{qutebrowser_version}`: The currently running qutebrowser
# version.  The default value is equal to the default user agent of
# QtWebKit/QtWebEngine, but with the `QtWebEngine/...` part removed for
# increased compatibility.  Note that the value read from JavaScript is
# always the global value.
# Type: FormatString
config.set(
    "content.headers.user_agent",
    "Mozilla/5.0 ({os_info}; rv:145.0) Gecko/20100101 Firefox/145.0",
    "https://accounts.google.com/*",
)

# User agent to send.  The following placeholders are defined:  *
# `{os_info}`: Something like "X11; Linux x86_64". * `{webkit_version}`:
# The underlying WebKit version (set to a fixed value   with
# QtWebEngine). * `{qt_key}`: "Qt" for QtWebKit, "QtWebEngine" for
# QtWebEngine. * `{qt_version}`: The underlying Qt version. *
# `{upstream_browser_key}`: "Version" for QtWebKit, "Chrome" for
# QtWebEngine. * `{upstream_browser_version}`: The corresponding
# Safari/Chrome version. * `{upstream_browser_version_short}`: The
# corresponding Safari/Chrome   version, but only with its major
# version. * `{qutebrowser_version}`: The currently running qutebrowser
# version.  The default value is equal to the default user agent of
# QtWebKit/QtWebEngine, but with the `QtWebEngine/...` part removed for
# increased compatibility.  Note that the value read from JavaScript is
# always the global value.
# Type: FormatString
config.set(
    "content.headers.user_agent",
    "Mozilla/5.0 ({os_info}) AppleWebKit/{webkit_version} (KHTML, like Gecko) {qt_key}/{qt_version} {upstream_browser_key}/{upstream_browser_version_short} Safari/{webkit_version}",
    "https://gitlab.gnome.org/*",
)

# Load images automatically in web pages.
# Type: Bool
config.set("content.images", True, CHROME_DEVTOOLS_URL)

# Load images automatically in web pages.
# Type: Bool
config.set("content.images", True, DEVTOOLS_URL)

# Allow JavaScript to read from or write to the clipboard. With
# QtWebEngine, writing the clipboard as response to a user interaction
# is always allowed. On Qt < 6.8, the `ask` setting is equivalent to
# `none` and permission needs to be granted manually via this setting.
# Type: JSClipboardPermission
# Valid values:
#   - none: Disable access to clipboard.
#   - access: Allow reading from and writing to the clipboard.
#   - access-paste: Allow accessing the clipboard and pasting clipboard content.
#   - ask: Prompt when requested (grants 'access-paste' permission).
c.content.javascript.clipboard = "access"

# Enable JavaScript.
# Type: Bool
config.set(CONTENT_JAVASCRIPT_ENABLED, True, CHROME_DEVTOOLS_URL)

# Enable JavaScript.
# Type: Bool
config.set(CONTENT_JAVASCRIPT_ENABLED, True, DEVTOOLS_URL)

# Enable JavaScript.
# Type: Bool
config.set(CONTENT_JAVASCRIPT_ENABLED, True, "chrome://*/*")

# Enable JavaScript.
# Type: Bool
config.set(CONTENT_JAVASCRIPT_ENABLED, True, "qute://*/*")

# Allow locally loaded documents to access remote URLs.
# Type: Bool
config.set(
    "content.local_content_can_access_remote_urls",
    True,
    "file:///home/neo/.local/share/qutebrowser/userscripts/*",
)

# Allow locally loaded documents to access other local URLs.
# Type: Bool
config.set(
    "content.local_content_can_access_file_urls",
    False,
    "file:///home/neo/.local/share/qutebrowser/userscripts/*",
)

# Open new windows in private browsing mode which does not record
# visited pages.
# Type: Bool
c.content.private_browsing = False

# Position of the tab bar.
# Type: Position
# Valid values:
#   - top
#   - bottom
#   - left
#   - right
c.tabs.position = "left"

# Width (in pixels or as percentage of the window) of the tab bar if
# it's vertical.
# Type: PercOrInt
c.tabs.width = "10%"

# Search engines which can be used via the address bar.  Maps a search
# engine name (such as `DEFAULT`, or `ddg`) to a URL with a `{}`
# placeholder. The placeholder will be replaced by the search term, use
# `{{` and `}}` for literal `{`/`}` braces.  The following further
# placeholds are defined to configure how special characters in the
# search terms are replaced by safe characters (called 'quoting'):  *
# `{}` and `{semiquoted}` quote everything except slashes; this is the
# most   sensible choice for almost all search engines (for the search
# term   `slash/and&amp` this placeholder expands to `slash/and%26amp`).
# * `{quoted}` quotes all characters (for `slash/and&amp` this
# placeholder   expands to `slash%2Fand%26amp`). * `{unquoted}` quotes
# nothing (for `slash/and&amp` this placeholder   expands to
# `slash/and&amp`). * `{0}` means the same as `{}`, but can be used
# multiple times.  The search engine named `DEFAULT` is used when
# `url.auto_search` is turned on and something else than a URL was
# entered to be opened. Other search engines can be used by prepending
# the search engine name to the search term, e.g. `:open google
# qutebrowser`.
# Type: Dict
c.url.searchengines = {
    "DEFAULT": "https://www.google.com/search?q={}",
    "jira": "https://oneline.atlassian.net/browse/CNPRD-{}",
    "y": "https://www.youtube.com/results?search_query={}",
    "n": "https://search.nixos.org/packages?channel=unstable&query={}",
}
# Render all web contents using a dark theme. On QtWebEngine < 6.7, this
# setting requires a restart and does not support URL patterns, only the
# global setting is applied. Example configurations from Chromium's
# `chrome://flags`: - "With simple HSL/CIELAB/RGB-based inversion": Set
# `colors.webpage.darkmode.algorithm` accordingly, and   set
# `colors.webpage.darkmode.policy.images` to `never`.  - "With selective
# image inversion": qutebrowser default settings.
# Type: Bool
c.colors.webpage.darkmode.enabled = True

# Render all web contents using a dark theme. On QtWebEngine < 6.7, this
# setting requires a restart and does not support URL patterns, only the
# global setting is applied. Example configurations from Chromium's
# `chrome://flags`: - "With simple HSL/CIELAB/RGB-based inversion": Set
# `colors.webpage.darkmode.algorithm` accordingly, and   set
# `colors.webpage.darkmode.policy.images` to `never`.  - "With selective
# image inversion": qutebrowser default settings.
# Type: Bool
config.set("colors.webpage.darkmode.enabled", False, "http://localhost:3000/*")
config.set("colors.webpage.darkmode.enabled", False, "*://*.one-line.com/*")

# Bindings for normal mode
config.bind("<Escape>", "fake-key <Escape>")

# Bindings for command mode
config.bind("<Ctrl+n>", "completion-item-focus next", mode="command")
config.bind("<Ctrl+p>", "completion-item-focus prev", mode="command")
config.bind("<Shift+Tab>", "command-history-prev", mode="command")
config.bind("<Tab>", "command-history-next", mode="command")


# * Helper Functions
def bind(key, command, mode):  # noqa: E302
    """Bind key to command in mode."""
    config.bind(key, command, mode=mode)


def nmap(key, command):
    """Bind key to command in normal mode."""
    bind(key, command, "normal")


def imap(key, command):
    """Bind key to command in insert mode."""
    bind(key, command, "insert")


def cmap(key, command):
    """Bind key to command in command mode."""
    bind(key, command, "command")


# UI
# TABS
c.tabs.new_position.unrelated = "next"

# GENERAL
c.keyhint.delay = 250

# * Key Bindings
# ** Reload Configuration
nmap("t.", "config-source")

nmap("gn", "navigate prev")
nmap("gp", "navigate next")

nmap("tn", "tab-move -")
nmap("tp", "tab-move +")

# ** Password manager: pass + qute-pass
imap("<Ctrl-p>", "spawn --userscript qute-pass")
imap("<Ctrl-Shift-u>", "spawn --userscript qute-pass --username-only")
imap("<Ctrl-Shift-p>", "spawn --userscript qute-pass --password-only")
imap("<Ctrl-Shift-o>", "spawn --userscript qute-pass --otp-only")

nmap(",p", "spawn --userscript qute-pass")
nmap(",pu", "spawn --userscript qute-pass --username-only")
nmap(",pp", "spawn --userscript qute-pass --password-only")
nmap(",po", "spawn --userscript qute-pass --otp-only")

# ** Insert/RL
imap('<Ctrl-w>', 'fake-key <Ctrl-backspace>')


# prevent c-w from closing tab
del c.bindings.default['normal']['<Ctrl-W>']
