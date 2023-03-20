# Hello World

## Requirements
- A build machine with Nix installed
- A Raspberry Pi with NixOS installed (see [these instructions](https://nix.dev/tutorials/installing-nixos-on-a-raspberry-pi))

### Develop
```bash
> nix develop
```

### Build
- native: `nix build .#hello-native`
- embedded: `nix build` (or `nix build .#hello-embedded`)

## Copy Build Artifacts to RaspberryPi
1. Build the embedded build target and copy the closure to the pi using the `BUILD_OUTPUT_PATH`:
```shell
> nix build
> nix-show-derivation jq '.[].outputs.out.path' |  nix-copy-closure --to $USER@$PI_HOST
```
2. Instantiate the build on the pi:
```shell
> ssh $USER@$PI_HOST
> nix-env -i ${BUILD_OUTPUT_PATH}
```
3. Run the executable on the pi:
```shell
> ${BUILD_OUTPUT_PATH}/bin/hello
Hello, world
```
