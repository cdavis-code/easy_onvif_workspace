# typed: false
# frozen_string_literal: true

# Homebrew formula for the ONVIF command-line tool.
#
# This is a template: `version` and the four `sha256` values are placeholders
# that `.github/workflows/homebrew-formula-update.yml` substitutes from a real
# GitHub Release before pushing to the tap. Install from the tap, not this file:
#
#   brew tap cdavis-code/easy-onvif
#   brew install easy-onvif-cli
class EasyOnvifCli < Formula
  desc "Command-line client for ONVIF IP cameras and NVRs (device, media, PTZ, imaging, recordings, replay, search)"
  homepage "https://github.com/cdavis-code/easy_onvif_workspace"
  version "0.0.0"
  license "MIT"

  on_macos do
    if Hardware::CPU.arm?
      url "https://github.com/cdavis-code/easy_onvif_workspace/releases/download/v#{version}/easy-onvif-cli-darwin-arm64"
      sha256 "DARWIN_ARM64_SHA256"
    else
      url "https://github.com/cdavis-code/easy_onvif_workspace/releases/download/v#{version}/easy-onvif-cli-darwin-amd64"
      sha256 "DARWIN_AMD64_SHA256"
    end
  end

  on_linux do
    if Hardware::CPU.arm?
      url "https://github.com/cdavis-code/easy_onvif_workspace/releases/download/v#{version}/easy-onvif-cli-linux-arm64"
      sha256 "LINUX_ARM64_SHA256"
    else
      url "https://github.com/cdavis-code/easy_onvif_workspace/releases/download/v#{version}/easy-onvif-cli-linux-amd64"
      sha256 "LINUX_AMD64_SHA256"
    end
  end

  # No `head` stanza: this formula installs a prebuilt binary only. Building
  # from source (`dart compile exe bin/onvif.dart`) is not wired into the
  # formula, so advertising --HEAD would install nothing.

  def install
    # Exactly one file is downloaded (the platform binary); rename it to the
    # stable user-facing command the Dart package already declares.
    binary = Dir["*"].find { |f| File.file?(f) }
    raise "no release binary found for #{version}" if binary.nil?

    bin.install binary => "onvif"
  end

  test do
    # A real zero-exit assertion, not OBS's `|| true`: `onvif --help` must
    # succeed and print usage, or the formula test fails.
    assert_match(/usage/i, shell_output("#{bin}/onvif --help 2>&1"))
  end
end
