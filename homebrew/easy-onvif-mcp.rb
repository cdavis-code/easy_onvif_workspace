# typed: false
# frozen_string_literal: true

# Homebrew formula for the ONVIF MCP stdio server.
#
# This is a template: `version` and the four `sha256` values are placeholders
# that `.github/workflows/homebrew-formula-update.yml` substitutes from a real
# GitHub Release before pushing to the tap. Install from the tap, not this file:
#
#   brew tap cdavis-code/easy-onvif
#   brew install easy-onvif-mcp
class EasyOnvifMcp < Formula
  desc "MCP server exposing ONVIF IP camera and NVR control (device, media, PTZ, imaging, recordings) over stdio"
  homepage "https://github.com/cdavis-code/easy_onvif_workspace"
  version "0.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/cdavis-code/easy_onvif_workspace/releases/download/v#{version}/easy-onvif-mcp-darwin-arm64"
      sha256 "DARWIN_ARM64_SHA256"
    else
      url "https://github.com/cdavis-code/easy_onvif_workspace/releases/download/v#{version}/easy-onvif-mcp-darwin-amd64"
      sha256 "DARWIN_AMD64_SHA256"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/cdavis-code/easy_onvif_workspace/releases/download/v#{version}/easy-onvif-mcp-linux-arm64"
      sha256 "LINUX_ARM64_SHA256"
    else
      url "https://github.com/cdavis-code/easy_onvif_workspace/releases/download/v#{version}/easy-onvif-mcp-linux-amd64"
      sha256 "LINUX_AMD64_SHA256"
    end
  end

  # No `head` stanza: the server is installed from a prebuilt binary; a source
  # build is not part of this formula and --HEAD would install nothing.

  def install
    binary = Dir["*"].find { |f| File.file?(f) }
    raise "no release binary found for #{version}" if binary.nil?

    bin.install binary => "easy-onvif-mcp"
  end

  test do
    # Both flags must exit 0. `brew test` fails on a non-zero shell_output, so
    # this is a hard assertion (unlike the OBS formulas, which use `|| true`).
    assert_match(/MCP stdio server/, shell_output("#{bin}/easy-onvif-mcp --help 2>&1"))
    assert_match(/easy-onvif-mcp \d+\.\d+/, shell_output("#{bin}/easy-onvif-mcp --version 2>&1"))
  end
end
