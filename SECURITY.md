# Security Policy

Language: English | [Español](SECURITY.es.md)

## Scope

`ffmpeg-video-filesize` is a local Bash script. It does not:

- Access the network
- Collect or transmit data
- Run a server or listen on any port
- Store credentials or secrets

The script reads a local video file, runs `ffmpeg` and `ffprobe` locally, and writes an output file to disk. All operations are local to your machine.

## Reporting a Vulnerability

If you find a security issue (for example, unsafe file handling, command injection, or unexpected behavior with crafted filenames), please report it through GitHub's **private vulnerability reporting**:

1. Go to the [Security tab](https://github.com/andreswatson/ffmpeg-video-filesize/security) of this repository
2. Click **Report a vulnerability**
3. Describe the issue, steps to reproduce, and potential impact

You will receive a response within a reasonable timeframe. Please do not open a public issue for security vulnerabilities.

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.0.x | Yes |
