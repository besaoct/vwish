#!/usr/bin/env bash
# IOS-01 spike (V-N9): precompile the Core Image Metal kernels into per-platform metallibs that the
# pods ship as plain resources (no Metal compilation during the app build).
#
#   -fcikernel kernels:  metal -c -fcikernel -target <air triple> ...; metallib -cikernel ...
#   [[stitchable]]:      metal -c -target <air triple> ...;  metal -framework CoreImage <air> (link)
#
# [[stitchable]] kernels reference Core Image's sampler/destination functions as external symbols,
# so they must be linked through the `metal` driver with `-framework CoreImage` (Xcode build
# setting MTLLINKER_FLAGS = -framework CoreImage); plain `metallib` fails with
# "LLVM ERROR: Undefined symbol: _ZNK9coreimage7Sampler6sampleEDv2_f".
#
# Xcode 26 no longer ships the Metal compiler: it is the optional "Metal Toolchain" component
# (`xcodebuild -downloadComponent MetalToolchain`, ~700 MB). When it is installed, `xcrun metal`
# is used. Otherwise set VW_METAL_TOOLCHAIN to a mounted Metal.xctoolchain (on the dev Mac the
# 26.4 toolchain asset already on disk was mounted read-only with hdiutil; see
# docs/editor/spikes/IOS-01.md §V-N9).
set -euo pipefail
HERE="$(cd "$(dirname "$0")/.." && pwd)"

if [[ -n "${VW_METAL_TOOLCHAIN:-}" ]]; then
  METAL="$VW_METAL_TOOLCHAIN/usr/bin/metal"
  METALLIB="$VW_METAL_TOOLCHAIN/usr/bin/metallib"
elif xcrun metal --version >/dev/null 2>&1; then
  METAL="xcrun metal"
  METALLIB="xcrun metallib"
else
  echo "No Metal compiler: install the Metal Toolchain component or set VW_METAL_TOOLCHAIN" >&2
  exit 1
fi

MIN_IOS=15.0
build() { # <source> <outdir> <basename> <cikernel:yes|no>
  local src="$1" out="$2" base="$3" ci="$4"
  mkdir -p "$out"
  local tmp; tmp="$(mktemp -d)"
  for pair in "iphoneos:air64-apple-ios${MIN_IOS}" "iphonesimulator:air64-apple-ios${MIN_IOS}-simulator"; do
    local sdk="${pair%%:*}" triple="${pair#*:}"
    local sysroot; sysroot="$(xcrun --sdk "$sdk" --show-sdk-path)"
    if [[ "$ci" == yes ]]; then
      $METAL -c -fcikernel -target "$triple" -isysroot "$sysroot" "$src" -o "$tmp/$base.$sdk.air"
      $METALLIB -cikernel "$tmp/$base.$sdk.air" -o "$out/$base.$sdk.metallib"
    else
      $METAL -c -target "$triple" -isysroot "$sysroot" "$src" -o "$tmp/$base.$sdk.air"
      $METAL -target "$triple" -isysroot "$sysroot" -framework CoreImage "$tmp/$base.$sdk.air" \
        -o "$out/$base.$sdk.metallib"
    fi
  done
  rm -rf "$tmp"
  {
    echo "source: $(basename "$src")"
    echo "source_sha256: $(shasum -a 256 "$src" | cut -d' ' -f1)"
    echo "compiler: $($METAL --version 2>&1 | head -1)"
    echo "flags: $([[ "$ci" == yes ]] && echo '-fcikernel / metallib -cikernel' || echo '[[stitchable]]: metal -c / metal -framework CoreImage')"
    echo "min_ios: $MIN_IOS"
    for f in "$out"/*.metallib; do echo "$(basename "$f"): $(shasum -a 256 "$f" | cut -d' ' -f1)"; done
  } > "$out/BUILD_INFO.txt"
}

build "$HERE/VWSpikeKernels/Kernels/vw_spike_kernels.ci.metal" "$HERE/VWSpikeKernels/Prebuilt" vw_spike_kernels yes
build "$HERE/VWSpikeStitchable/Kernels/vw_spike_stitchable.metal" "$HERE/VWSpikeStitchable/Prebuilt" vw_spike_stitchable no
ls -la "$HERE"/VWSpikeKernels/Prebuilt "$HERE"/VWSpikeStitchable/Prebuilt
