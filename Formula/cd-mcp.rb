# Homebrew formula for the CarryDictionary MCP server (cd_mcp).
#
# Ships a self-contained binary built with `dart build cli` — the native
# sqlite3 shared library is bundled, so no Dart SDK is needed at runtime. The
# source code of CarryDictionary stays private; only this formula and the
# prebuilt release tarballs (attached to this tap repo's GitHub Releases) are
# public.
#
# Platform support:
#   * macOS arm64  — official, tested.
#   * Linux x86_64 — beta (built by the release CI; Homebrew on Linux).
#   * macOS Intel  — not published (GitHub Intel runners are deprecated/scarce).
# The PLACEHOLDER sha256 (zeros) for Linux is overwritten by the release workflow
# when it publishes that artifact.
class CdMcp < Formula
  desc "CarryDictionary MCP server: expose your local dictionary to any MCP/AI client"
  homepage "https://github.com/HalkPapa/homebrew-carrydictionary"
  version "0.1.0"
  # Source is kept private; this is a personal redistribution of prebuilt binaries.

  on_macos do
    on_arm do
      url "https://github.com/HalkPapa/homebrew-carrydictionary/releases/download/cd_mcp-v0.1.0/cd_mcp-0.1.0-macos-arm64.tar.gz"
      sha256 "f5535c0feff89d0205bee9abcf3e73c54d1984b23796f1569a87b6bbfac0eed6"
    end

    on_intel do
      # macOS Intel build is not published (GitHub's Intel mac CI runners are
      # deprecated/scarce). Use Apple Silicon, or build from source.
      odie "cd_mcp: a macOS x86_64 (Intel) build is not published. " \
           "Use Apple Silicon, or build from source."
    end
  end

  on_linux do
    on_intel do
      # beta — filled by release CI (ubuntu runner)
      url "https://github.com/HalkPapa/homebrew-carrydictionary/releases/download/cd_mcp-v0.1.0/cd_mcp-0.1.0-linux-x86_64.tar.gz"
      sha256 "cbaad5dca3c19b0e191290ef78e3d7ae39555971bd8056d010bcb33d62be487e"
    end

    on_arm do
      odie "cd_mcp: a Linux arm64 build has not been published yet."
    end
  end

  def install
    # Preserve the dart-build bundle layout: the executable in bin/ finds its
    # sibling lib/ shared library via @loader_path/../lib (macOS) / $ORIGIN/../lib
    # (Linux) at runtime. Keep both together under libexec and expose the binary
    # on PATH via a symlink (the symlink target's real location is what the
    # loader resolves against, so the bundled library is still found).
    libexec.install "bin", "lib"
    bin.install_symlink libexec/"bin/cd_mcp"
  end

  def caveats
    <<~EOS
      cd_mcp is an MCP (Model Context Protocol) stdio server. Register it with an
      MCP client and point CD_DB_PATH at your CarryDictionary database, e.g. for
      Claude Code (.mcp.json):

        {
          "mcpServers": {
            "carry-dictionary": {
              "command": "cd_mcp",
              "env": { "CD_DB_PATH": "/absolute/path/to/cd_core.sqlite" }
            }
          }
        }

      If CD_DB_PATH is unset it defaults to a platform-appropriate path:
        macOS: ~/Library/Application Support/CarryDictionary/cd_core.sqlite
        Linux: $XDG_DATA_HOME/CarryDictionary/cd_core.sqlite (or ~/.local/share/...)

      Note: macOS arm64 is the official target; Linux / Windows(Scoop) are beta.
      macOS Intel is not published — use Apple Silicon or build from source.
    EOS
  end

  test do
    require "open3"
    req = '{"jsonrpc":"2.0","id":1,"method":"initialize","params":' \
          '{"protocolVersion":"2024-11-05","capabilities":{},' \
          '"clientInfo":{"name":"brew-test","version":"0"}}}'
    out, = Open3.capture2(
      { "CD_DB_PATH" => "#{testpath}/cd.sqlite" },
      bin/"cd_mcp",
      stdin_data: "#{req}\n",
    )
    assert_match "carry-dictionary", out
  end
end
