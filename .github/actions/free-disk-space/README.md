# free-disk-space

Local composite action vendored from
[`jlumbroso/free-disk-space@v1.3.1`](https://github.com/jlumbroso/free-disk-space/tree/v1.3.1)
because that upstream action is not on this enterprise's GitHub Actions
allowlist. Used by `build.yml` and `iso-release.yml` to reclaim disk
space on `ubuntu-24.04` runners before container builds.

## Refresh

```bash
TAG=v1.3.1   # or newer
curl -fsSL "https://raw.githubusercontent.com/jlumbroso/free-disk-space/${TAG}/action.yml" \
    -o .github/actions/free-disk-space/action.yml
curl -fsSL "https://raw.githubusercontent.com/jlumbroso/free-disk-space/${TAG}/LICENSE" \
    -o .github/actions/free-disk-space/LICENSE
```

Then re-prepend the vendor header to `action.yml` (preserve the comment
block at the top) and bump the `<tag>` reference there.

## License

MIT, copyright (c) 2022 Jérémie Lumbroso. See `LICENSE`.
