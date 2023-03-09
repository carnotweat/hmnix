#!/usr/bin/env bash
set -euo pipefail

cd "$(readlink -f "$(dirname "$(readlink -f "$0")")/..")"

nix build .#homeManagerConfigurations.xameer.activationPackage
./result/activate

#home-manager switch -f xameer-home.nix
