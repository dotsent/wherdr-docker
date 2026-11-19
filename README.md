# Docker image for wherdr

The base image packages wherdr, herdr-core and an SSH client. Its entrypoint
starts herdr-core and serves wherdr as the unprivileged `coder` user. The image
uses the local UI patch that removes the open-network banner.

## Publish

Push an annotated tag matching the wherdr version in `Dockerfile`. For example,
`v3.2.0-r1` publishes `ghcr.io/dotsent/wherdr-docker:3.2.0-r1` for Linux amd64
and arm64. GitHub Actions builds the base image and checks its health endpoint
before publishing. To publish an image revision with the same upstream version,
increment the `r` suffix.
Set the GHCR package visibility to public if deployment hosts pull anonymously.

## Upstream

- [wherdr](https://github.com/afloury/wherdr) (MIT)
- [herdr-core](https://github.com/herdrdev/herdr-core) (Apache-2.0)
