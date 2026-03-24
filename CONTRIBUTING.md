# Contributing

## Reporting bugs

Open an issue and use the bug report template. Include steps to reproduce, expected vs actual behavior, and your environment (OS, ffmpeg, bash).

## Suggesting features

Open an issue first to describe the idea and use case before submitting a pull request.

## Code style

- Bash only; keep scripts portable where reasonable.
- Changes must be ShellCheck clean (`shellcheck ffmpeg-filesize.sh`).
- Avoid unnecessary comments; prefer clear names and structure.

## Testing

Before opening a PR:

- `bash -n ffmpeg-filesize.sh`
- `./ffmpeg-filesize.sh --help`
- Run the script against a short sample video relevant to your change.

## License

Contributions are accepted under the same terms as the project: the MIT License.
