{
  description = "flake for sing-box";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      # Systems supported
      allSystems = [
        "x86_64-linux" # 64-bit Intel/AMD Linux
        "aarch64-linux" # 64-bit ARM Linux
        "x86_64-darwin" # 64-bit Intel macOS
        "aarch64-darwin" # 64-bit ARM macOS
      ];

      # Helper to provide system-specific attributes
      forAllSystems = f: nixpkgs.lib.genAttrs allSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      packages = forAllSystems ({ pkgs }: {
        default = pkgs.buildGoModule rec {
          pname = "sing-box";
          version = "1.10.0-beta.10";

          src = pkgs.fetchFromGitHub {
            owner = "SagerNet";
            repo = pname;
            rev = "v${version}";
            hash = "sha256-J9/sI5zpWbqSUmdnIbGeaamO1uFEJpggf8zD0KELWHo=";
          };

          vendorHash = "sha256-G52zvjU3D/UdsHYtYCXle9yLvJkUuNmWXdBJVU+VCBc=";

          tags = [
            "with_quic"
            "with_dhcp"
            "with_wireguard"
            "with_ech"
            "with_utls"
            "with_reality_server"
            "with_acme"
            "with_clash_api"
            "with_gvisor"
          ];
          subPackages = [ "cmd/sing-box" ];

          nativeBuildInputs = [ pkgs.installShellFiles ];

          ldflags = [
            "-X=github.com/sagernet/sing-box/constant.Version=${version}"
          ];

          postInstall = let emulator = pkgs.stdenv.hostPlatform.emulator pkgs.buildPackages; in ''
            installShellCompletion --cmd sing-box \
              --bash <(${emulator} $out/bin/sing-box completion bash) \
              --fish <(${emulator} $out/bin/sing-box completion fish) \
              --zsh  <(${emulator} $out/bin/sing-box completion zsh )

            substituteInPlace release/config/sing-box{,@}.service \
              --replace-fail "/usr/bin/sing-box" "$out/bin/sing-box" \
              --replace-fail "/bin/kill" "${pkgs.coreutils}/bin/kill"
            install -Dm444 -t "$out/lib/systemd/system/" release/config/sing-box{,@}.service
          '';

          passthru = {
            updateScript = pkgs.nix-update-script { };
            tests = { inherit (pkgs.nixosTests) sing-box; };
          };

          meta = with pkgs.lib;{
            homepage = "https://sing-box.sagernet.org";
            description = "Universal proxy platform";
            license = licenses.gpl3Plus;
            maintainers = with maintainers; [ nickcao ];
            mainProgram = "sing-box";
          };
        };
      });
    };
}
