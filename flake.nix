{
  outputs = { nixpkgs, ... }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    systems = [ "x86_64-linux" ];
    simple-transmission-exporter = pkgs: pkgs.python3Packages.buildPythonPackage (let
      pythonEnv = pkgs.python3.withPackages (ps: with ps; [
        transmissionrpc
        flask
      ]);
    in {
      name = "simple-transmission-exporter";
      src = ./.;
      propagatedBuildInputs =  [
        pythonEnv
      ];
    });
  in {
    packages = pkgs.lib.genAttrs systems (system: let
      pkgs = import nixpkgs { inherit system; };
    in {
      simple-transmission-exporter = simple-transmission-exporter pkgs;
    });
    overlay = (final: prev: {
      simple-transmission-exporter = (simple-transmission-exporter pkgs);
    });
    nixosModules.simple-transmission-exporter = { config, lib, pkgs, ... }: with lib.types; let
      cfg = config.services.simple-transmission-exporter;
    in {
      options = {
        services.simple-transmission-exporter = {
          enable = lib.mkEnableOption "services.simple-transmission-exporter";
          host = lib.mkOption {
            type = str;
            default = "localhost";
          };
          port = lib.mkOption {
            type = int;
            default = 9092;
          };
          username = lib.mkOption {
            type = str;
            default = "transmission";
          };
          passwordFile = lib.mkOption {
            type = str;
          };
          openFirewall = lib.mkOption {
            type = bool;
            default = false;
          };
          metricsPort = lib.mkOption {
            type = int;
            default = 29091;
          };
        };
      };
      config = lib.mkIf cfg.enable {
        users = {
          extraUsers.transmission.group = "users";
          groups.transmission = {};
        };
        networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [
          cfg.metricsPort
        ];
        systemd.services.simple-transmission-exporter = {
          description = "Simple Transmission Exporter";
          enable = true;
          wantedBy = [ "multi-user.target" ];
          environment = {
            TRANSMISSION_HOST = cfg.host;
            TRANSMISSION_PORT = toString cfg.port;
            TRANSMISSION_USER = cfg.username;
          };
          serviceConfig = {
            Restart = "always";
            User = "transmission";
            ExecStart = let
              package = pkgs.writeScriptBin "simple-transmission-exporter-wrapped" ''
                  #!${pkgs.stdenv.shell}
                  export TRANSMISSION_PASSWORD="$(cat ${cfg.passwordFile})"
                  ${pkgs.simple-transmission-exporter}/bin/simple-transmission-exporter
                '';
            in "${package}/bin/simple-transmission-exporter-wrapped";
          };
        };
      };
    };
  };
 }
