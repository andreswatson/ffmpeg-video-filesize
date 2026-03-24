#!/usr/bin/env bash

set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
DEFAULT_AUDIO_BITRATE_KBPS=128
DEFAULT_PRESET="medium"
DEFAULT_VIDEO_ENCODER="libx264"
DEFAULT_GPU_VIDEO_ENCODER="h264_videotoolbox"
SAFETY_FACTOR="0.98"
VERSION="1.0.0"

usage() {
    cat <<EOF
Usage:
  $SCRIPT_NAME [options] <input-file> <target-size>

Resize a video to fit approximately within a target file size.
The script uses ffprobe to read the duration and ffmpeg two-pass
encoding to calculate and apply the required video bitrate.

Target size formats:
  25      -> 25 MB
  25mb    -> 25 MB
  800kb   -> 800 KB
  1gb     -> 1 GB

Options:
  -o, --output <path>          Output file path. Default: <input>-<size>.mp4
  -a, --audio-bitrate <kbps>   AAC audio bitrate in kbps. Default: $DEFAULT_AUDIO_BITRATE_KBPS
                               Use 0 to remove audio.
  -e, --video-encoder <name>   Video encoder. Default: $DEFAULT_VIDEO_ENCODER
  -g, --gpu                    Use macOS VideoToolbox H.264 encoding
                               ($DEFAULT_GPU_VIDEO_ENCODER)
  -p, --preset <preset>        Encoder preset. Default: $DEFAULT_PRESET
  -f, --force                  Overwrite the output file if it already exists
  -t, --template <name>        Use a built-in size preset:
                               whatsapp (95mb), whatsapp-safe (60mb),
                               gmail (24mb), email (20mb),
                               preview (8mb), mobile (16mb)
  -h, --help                   Show this help message
  -v, --version                Show version and exit

Examples:
  $SCRIPT_NAME input.mov 25
  $SCRIPT_NAME input.mov 25mb
  $SCRIPT_NAME input.mov 1gb
  $SCRIPT_NAME -a 96 -p slow input.mov 8.5mb
  $SCRIPT_NAME --gpu input.mov 95mb
  $SCRIPT_NAME --video-encoder $DEFAULT_GPU_VIDEO_ENCODER input.mov 95mb
  $SCRIPT_NAME -o compressed.mp4 input.mov 700mb
  $SCRIPT_NAME -o compressed.mov input.mp4 1gb
EOF
}

fail() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "'$1' is required but was not found in PATH."
}

is_positive_number() {
    awk -v value="$1" 'BEGIN { exit !(value ~ /^[0-9]+([.][0-9]+)?$/ && value > 0) }'
}

is_non_negative_integer() {
    [[ "$1" =~ ^[0-9]+$ ]]
}

require_ffmpeg_encoder() {
    ffmpeg -hide_banner -h "encoder=$1" >/dev/null 2>&1 || \
        fail "Video encoder '$1' is not available in this ffmpeg build."
}

parse_target_size() {
    local raw_size="$1"
    local size_value
    local size_unit
    local unit_multiplier

    if [[ ! "$raw_size" =~ ^([0-9]+([.][0-9]+)?)([[:alpha:]]*)$ ]]; then
        fail "Target size must look like 25, 25mb, 800kb, or 1gb."
    fi

    size_value="${BASH_REMATCH[1]}"
    size_unit="$(printf '%s' "${BASH_REMATCH[3]}" | tr '[:upper:]' '[:lower:]')"

    case "$size_unit" in
        ""|m|mb)
            parsed_target_unit="mb"
            unit_multiplier=$((1024 * 1024))
            ;;
        k|kb)
            parsed_target_unit="kb"
            unit_multiplier=1024
            ;;
        g|gb)
            parsed_target_unit="gb"
            unit_multiplier=$((1024 * 1024 * 1024))
            ;;
        b)
            parsed_target_unit="b"
            unit_multiplier=1
            ;;
        *)
            fail "Unsupported target size unit: $size_unit. Use kb, mb, or gb."
            ;;
    esac

    parsed_target_value="$size_value"
    parsed_target_label="${parsed_target_value}${parsed_target_unit}"
    parsed_target_bytes="$(awk \
        -v value="$parsed_target_value" \
        -v multiplier="$unit_multiplier" \
        'BEGIN { printf "%.0f", value * multiplier }')"

    if ! awk -v bytes="$parsed_target_bytes" 'BEGIN { exit !(bytes > 0) }'; then
        fail "Target size must be greater than zero."
    fi
}

resolve_template() {
    local template
    template="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$template" in
        whatsapp)       echo "95mb" ;;
        whatsapp-safe)  echo "60mb" ;;
        gmail)          echo "24mb" ;;
        email)          echo "20mb" ;;
        preview)        echo "8mb"  ;;
        mobile)         echo "16mb" ;;
        *)              fail "Unknown template: $1. Available: whatsapp, whatsapp-safe, gmail, email, preview, mobile." ;;
    esac
}

audio_bitrate_kbps="$DEFAULT_AUDIO_BITRATE_KBPS"
preset="$DEFAULT_PRESET"
video_encoder="$DEFAULT_VIDEO_ENCODER"
output_file=""
force_overwrite=0
template_size=""
declare -a positional_args=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output)
            [[ $# -ge 2 ]] || fail "Missing value for $1."
            output_file="$2"
            shift 2
            ;;
        -a|--audio-bitrate)
            [[ $# -ge 2 ]] || fail "Missing value for $1."
            audio_bitrate_kbps="$2"
            shift 2
            ;;
        -p|--preset)
            [[ $# -ge 2 ]] || fail "Missing value for $1."
            preset="$2"
            shift 2
            ;;
        -e|--video-encoder)
            [[ $# -ge 2 ]] || fail "Missing value for $1."
            video_encoder="$2"
            shift 2
            ;;
        -g|--gpu)
            video_encoder="$DEFAULT_GPU_VIDEO_ENCODER"
            shift
            ;;
        -f|--force)
            force_overwrite=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -v|--version)
            printf '%s %s\n' "$SCRIPT_NAME" "$VERSION"
            exit 0
            ;;
        -t|--template)
            [[ $# -ge 2 ]] || fail "Missing value for $1."
            template_size="$(resolve_template "$2")"
            shift 2
            ;;
        --)
            shift
            while [[ $# -gt 0 ]]; do
                positional_args+=("$1")
                shift
            done
            ;;
        -*)
            fail "Unknown option: $1"
            ;;
        *)
            positional_args+=("$1")
            shift
            ;;
    esac
done

if [[ -n "$template_size" ]]; then
    [[ "${#positional_args[@]}" -eq 1 ]] || {
        usage
        exit 1
    }
    input_file="${positional_args[0]}"
    target_size_input="$template_size"
else
    [[ "${#positional_args[@]}" -eq 2 ]] || {
        usage
        exit 1
    }
    input_file="${positional_args[0]}"
    target_size_input="${positional_args[1]}"
fi

require_command ffmpeg
require_command ffprobe
require_command awk
require_command wc
require_command rm
require_command mktemp

[[ -f "$input_file" ]] || fail "Input file does not exist: $input_file"
[[ -r "$input_file" ]] || fail "Input file is not readable: $input_file"
is_non_negative_integer "$audio_bitrate_kbps" || fail "Audio bitrate must be a non-negative integer in kbps."
require_ffmpeg_encoder "$video_encoder"

parse_target_size "$target_size_input"

input_size_bytes="$(wc -c < "$input_file" | tr -d '[:space:]')"
input_size_mb="$(awk -v bytes="$input_size_bytes" 'BEGIN { printf "%.2f", bytes / 1024 / 1024 }')"
target_size_bytes="$parsed_target_bytes"
target_size_label="$parsed_target_label"
target_size_mb="$(awk -v bytes="$target_size_bytes" 'BEGIN { printf "%.2f", bytes / 1024 / 1024 }')"

if ! awk -v input="$input_size_bytes" -v target="$target_size_bytes" 'BEGIN { exit !(target < input) }'; then
    fail "Input file is already smaller than or equal to the requested target size. Keep the original file or choose a smaller target."
fi

if [[ -z "$output_file" ]]; then
    input_base="${input_file%.*}"
    output_file="${input_base}-${target_size_label}.mp4"
fi

output_dir="$(dirname "$output_file")"
[[ -d "$output_dir" ]] || fail "Output directory does not exist: $output_dir"

if [[ "$force_overwrite" -eq 0 && -e "$output_file" ]]; then
    fail "Output file already exists. Use --force to overwrite: $output_file"
fi

duration_seconds="$(ffprobe \
    -v error \
    -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 \
    "$input_file")"

[[ -n "$duration_seconds" ]] || fail "Could not read the video duration with ffprobe."

is_positive_number "$duration_seconds" || fail "The input video has an invalid duration: $duration_seconds"

total_bitrate_kbps="$(awk \
    -v size_bytes="$target_size_bytes" \
    -v duration="$duration_seconds" \
    -v safety="$SAFETY_FACTOR" \
    'BEGIN { printf "%.0f", ((size_bytes * 8) / 1000 / duration) * safety }')"

video_bitrate_kbps="$(awk \
    -v total="$total_bitrate_kbps" \
    -v audio="$audio_bitrate_kbps" \
    'BEGIN { printf "%.0f", total - audio }')"

if ! awk -v bitrate="$video_bitrate_kbps" 'BEGIN { exit !(bitrate > 0) }'; then
    fail "The target size is too small for the selected audio bitrate. Increase the size or lower --audio-bitrate."
fi

passlog_prefix="$(mktemp "${TMPDIR:-/tmp}/ffmpeg-filesize.XXXXXX")"

cleanup() {
    rm -f "${passlog_prefix}"*
}

trap cleanup EXIT

is_videotoolbox_encoder=0
preset_display="$preset"
if [[ "$video_encoder" == *_videotoolbox ]]; then
    is_videotoolbox_encoder=1
    preset_display="n/a for $video_encoder"
fi

printf 'Input file:        %s\n' "$input_file"
printf 'Original size:     %s MB\n' "$input_size_mb"
printf 'Target size:       %s (%s MB)\n' "$target_size_label" "$target_size_mb"
printf 'Duration:          %.2f seconds\n' "$duration_seconds"
printf 'Video encoder:     %s\n' "$video_encoder"
printf 'Video bitrate:     %sk\n' "$video_bitrate_kbps"
if [[ "$audio_bitrate_kbps" -eq 0 ]]; then
    printf 'Audio:             disabled\n'
else
    printf 'Audio bitrate:     %sk AAC\n' "$audio_bitrate_kbps"
fi
printf 'Preset:            %s\n' "$preset_display"
printf 'Output file:       %s\n\n' "$output_file"

if [[ "$is_videotoolbox_encoder" -eq 1 ]]; then
    ffmpeg \
        -hide_banner \
        -y \
        -i "$input_file" \
        -c:v "$video_encoder" \
        -pix_fmt yuv420p \
        -b:v "${video_bitrate_kbps}k" \
        -pass 1 \
        -passlogfile "$passlog_prefix" \
        -an \
        -f mp4 \
        /dev/null
else
    ffmpeg \
        -hide_banner \
        -y \
        -i "$input_file" \
        -c:v "$video_encoder" \
        -preset "$preset" \
        -pix_fmt yuv420p \
        -b:v "${video_bitrate_kbps}k" \
        -pass 1 \
        -passlogfile "$passlog_prefix" \
        -an \
        -f mp4 \
        /dev/null
fi

ffmpeg_overwrite_flag="-n"
if [[ "$force_overwrite" -eq 1 ]]; then
    ffmpeg_overwrite_flag="-y"
fi

declare -a audio_args
if [[ "$audio_bitrate_kbps" -eq 0 ]]; then
    audio_args=(-an)
else
    audio_args=(-c:a aac -b:a "${audio_bitrate_kbps}k")
fi

if [[ "$is_videotoolbox_encoder" -eq 1 ]]; then
    ffmpeg \
        -hide_banner \
        "$ffmpeg_overwrite_flag" \
        -i "$input_file" \
        -c:v "$video_encoder" \
        -pix_fmt yuv420p \
        -b:v "${video_bitrate_kbps}k" \
        -pass 2 \
        -passlogfile "$passlog_prefix" \
        "${audio_args[@]}" \
        -movflags +faststart \
        "$output_file"
else
    ffmpeg \
        -hide_banner \
        "$ffmpeg_overwrite_flag" \
        -i "$input_file" \
        -c:v "$video_encoder" \
        -preset "$preset" \
        -pix_fmt yuv420p \
        -b:v "${video_bitrate_kbps}k" \
        -pass 2 \
        -passlogfile "$passlog_prefix" \
        "${audio_args[@]}" \
        -movflags +faststart \
        "$output_file"
fi

output_size_bytes="$(wc -c < "$output_file" | tr -d '[:space:]')"
output_size_mb="$(awk -v bytes="$output_size_bytes" 'BEGIN { printf "%.2f", bytes / 1024 / 1024 }')"

printf '\nDone.\n'
printf 'Created:           %s\n' "$output_file"
printf 'Final size:        %s MB\n' "$output_size_mb"
