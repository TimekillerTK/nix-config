# Podman services
# Source: https://discourse.nixos.org/t/nixos-config-for-docker-containers-using-rootless-podman/29635/5
{pkgs, ...}: let
  podman-py = p:
    with p; [
      (
        buildPythonPackage rec {
          pname = "podman";
          version = "4.5.1";
          src = fetchPypi {
            inherit pname version;
            sha256 = "sha256-znZnjuOFIy6YiwbtVXoCFNnNdtVJldWpDUNXC13RygQ=";
          };
          doCheck = false;
          propagatedBuildInputs = [
            # Specify dependencies
            pkgs.python310Packages.pyxdg
            pkgs.python310Packages.requests
            pkgs.python310Packages.setuptools
            pkgs.python310Packages.sphinx
            pkgs.python310Packages.tomli
            pkgs.python310Packages.urllib3
            pkgs.python310Packages.wheel
          ];
        }
      )
    ];
in {
  environment.systemPackages = with pkgs; [
    (python310.withPackages podman-py)
  ];
  environment.shellAliases = {
    pps = "podman ps --format 'table {{ .Names }}\t{{ .Status }}' --sort names";
    pclean = "podman ps -a | grep -v 'CONTAINER\|_config\|_data\|_run' | cut -c-12 | xargs podman rm 2>/dev/null";
    piclean = "podman images | grep '<none>' | grep -P '[1234567890abcdef]{12}' -o | xargs -L1 podman rmi 2>/dev/null";
  };

  systemd.services.pod-cloud = {
    description = "Start podman 'nextcloud' pod";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    requiredBy = ["podman-mariadb.service" "podman-nextcloud.service" "podman-redis.service"];
    unitConfig = {
      RequiresMountsFor = "/run/containers";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "-${pkgs.podman}/bin/podman pod create cloud";
    };
    path = [pkgs.zfs pkgs.podman];
  };
  systemd.services.pod-download = {
    description = "Start podman 'download' pod";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    requiredBy = ["podman-jackett.service" "podman-radarr.service" "podman-sabnzbd.service" "podman-sonarr.service"];
    unitConfig = {
      RequiresMountsFor = "/run/containers";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "-${pkgs.podman}/bin/podman pod create download";
    };
    path = [pkgs.zfs pkgs.podman];
  };
  systemd.services.pod-flux = {
    description = "Start podman 'flux' pod";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    requiredBy = ["podman-miniflux.service" "podman-postgres.service"];
    unitConfig = {
      RequiresMountsFor = "/run/containers";
    };
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "-${pkgs.podman}/bin/podman pod create --dns=192.168.1.1 flux";
    };
    path = [pkgs.podman pkgs.zfs];
  };
  systemd.services.pod-wireguard = {
    description = "Start podman 'wg' pod";
    wants = ["network-online.target"];
    after = ["network-online.target"];
    requiredBy = ["podman-wireguard-client.service" "podman-qbitorrent.service" "podman-socks-proxy.service"];
    unitConfig = {
      RequiresMountsFor = "/run/containers";
    };
    serviceConfig = {
      Type = "oneshot";
      # 8081 - qbitorrent, 2222 - socks-proxy
      ExecStart = "-${pkgs.podman}/bin/podman pod create -p 8081:8081 -p 2222:22 wg";
    };
    path = [pkgs.zfs pkgs.podman];
  };
  systemd.timers."memories" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "daily";
      OnBootSec = "5m";
      Unit = "memories.service";
    };
  };
  systemd.services."memories" = {
    script = ''
      ${pkgs.podman}/bin/podman run --rm \
      -v /home/firecat53/docs/family/scott/wiki/diary:/data/journal \
      -v /mnt/media/pictures/Family\ Pictures:/data/pictures \
      -v /srv/rss:/srv/rss \
      memories
    '';
    path = [pkgs.podman pkgs.zfs];
  };
  systemd.timers."nextcloud_cron" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "5m";
      Unit = "nextcloud_cron.service";
    };
  };
  systemd.services."nextcloud_cron" = {
    bindsTo = ["podman-nextcloud.service" "podman-mariadb.service" "podman-redis.service"];
    after = ["network-online.target" "podman-nextcloud.service" "podman-mariadb.service" "podman-redis.service"];
    script = "${pkgs.podman}/bin/podman exec -u www-data nextcloud php -f cron.php";
    path = [pkgs.podman pkgs.zfs];
  };
  systemd.timers."nextcloud_files_update" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2m";
      OnUnitActiveSec = "15m";
      Unit = "nextcloud_files_update.service";
    };
  };
  systemd.services."nextcloud_files_update" = {
    bindsTo = ["podman-nextcloud.service" "podman-mariadb.service" "podman-redis.service"];
    after = ["network-online.target" "podman-nextcloud.service" "podman-mariadb.service" "podman-redis.service"];
    script = ''
      ${pkgs.podman}/bin/podman exec -u www-data nextcloud ./occ files:scan -q --all
      ${pkgs.podman}/bin/podman exec -u www-data nextcloud ./occ memories:index -q
      ${pkgs.podman}/bin/podman exec -u www-data nextcloud ./occ preview:pre-generate
    '';
    path = [pkgs.podman pkgs.zfs];
  };
  systemd.timers."picture_copy" = {
    enable = true;
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5m";
      OnCalendar = "daily";
      Unit = "picture_copy.service";
    };
  };
  systemd.services."picture_copy" = {
    script = "${pkgs.python3}/bin/python3 /home/firecat53/docs/family/scott/src/scripts.git/bin/pix.py";
    path = [pkgs.python3 pkgs.rsync pkgs.exiftool];
    serviceConfig = {
      User = "firecat53";
    };
  };
  systemd.timers."podman_db_backup" = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5m";
      OnCalendar = "daily";
      RandomizedDelaySec = "15m";
      FixedRandomDelay = true;
      Unit = "podman_db_backup.service";
    };
  };
  systemd.services."podman_db_backup" = {
    script = let
      python3 = pkgs.python3.withPackages podman-py;
    in "${python3.interpreter} /home/firecat53/docs/family/scott/src/scripts.git/bin/podman_db_backup_homeserver.py";
    path = [pkgs.python3];
  };

  ## Podman containers

  virtualisation.podman = {
    enable = true;
    extraPackages = [pkgs.zfs];
  };
  virtualisation.containers.storage.settings = {
    storage = {
      driver = "zfs";
      graphroot = "/var/lib/containers/storage";
      runroot = "/run/containers/storage";
    };
  };
  virtualisation.oci-containers.containers = {
    gollum = {
      image = "gollum";
      autoStart = true;
      cmd = ["--allow-uploads" "page" "--ref" "main"];
      volumes = [
        "/home/firecat53/docs/family/scott/wiki:/home/gollum/wiki"
        "/home/firecat53/.gitconfig:/home/gollum/.gitconfig:ro"
      ];
      user = "1000:100";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.gollum.rule=Host(`gollum.domain.com`)"
        "--label=traefik.http.routers.gollum.entrypoints=websecure"
        "--label=traefik.http.routers.gollum.tls.certResolver=le"
        "--label=traefik.http.routers.gollum.middlewares=auth-gollum"
        "--label=traefik.http.middlewares.auth-gollum.basicauth.users=firecat53:$apr1$xxxxxx"
        "--label=traefik.http.services.gollum.loadbalancer.server.port=4567"
      ];
    };
    jackett = {
      image = "jackett";
      autoStart = true;
      user = "1000:100";
      extraOptions = [
        "--init=true"
        "--pod=download"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.jackett.rule=Host(`jackett.domain.com`)"
        "--label=traefik.http.routers.jackett.entrypoints=websecure"
        "--label=traefik.http.routers.jackett.tls.certResolver=le"
        "--label=traefik.http.routers.jackett.middlewares=headers"
        "--label=traefik.http.services.jackett.loadbalancer.server.port=9117"
      ];
      volumes = ["jackett_config:/config" "/mnt/downloads:/data"];
    };
    # Note: jellyfin server discovery doesn't work without host networking (ports 7359 and 1900 udp)
    jellyfin = {
      image = "jellyfin";
      autoStart = true;
      user = "1000:100";
      ports = ["1900:1900/udp" "7359:7359/udp"];
      extraOptions = [
        "--device=/dev/dri"
        "--init=true"
        "--tz=local"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.jellyfin.rule=Host(`jellyfin.domain.com`)"
        "--label=traefik.http.routers.jellyfin.entrypoints=websecure"
        "--label=traefik.http.routers.jellyfin.tls.certResolver=le"
        "--label=traefik.http.routers.jellyfin.middlewares=headers"
        "--label=traefik.http.services.jellyfin.loadbalancer.server.port=8096"
      ];
      volumes = [
        "jellyfin_config:/config"
        "jellyfin_cache:/cache"
        "/mnt/media:/media"
        "/mnt/downloads:/downloads"
      ];
    };
    mariadb = {
      image = "docker.io/library/mariadb:latest";
      autoStart = true;
      user = "mysql:mysql";
      cmd = ["--transaction-isolation=READ-COMMITTED" "--log-bin=msqyld-bin" "--binlog-format=ROW"];
      extraOptions = ["--pod=cloud"];
      volumes = ["mariadb_data:/var/lib/mysql"];
      environment = {
        MYSQL_DATABASE = "nextcloud";
        MYSQL_USER = "nextcloud";
        MYSQL_PASSWORD = "xxxxx";
        MYSQL_ROOT_PASSWORD = "yyyyyy";
      };
      dependsOn = ["redis"];
    };
    miniflux = {
      image = "miniflux";
      autoStart = true;
      user = "1000:100";
      environment = {
        DATABASE_URL = "user=miniflux password=miniflux dbname=miniflux sslmode=disable host=postgres";
        POLLING_FREQUENCY = "15";
        RUN_MIGRATIONS = "1";
      };
      dependsOn = ["postgres"];
      extraOptions = [
        "--dns=192.168.1.1"
        "--pod=flux"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.miniflux.rule=Host(`rss.domain.com`)"
        "--label=traefik.http.routers.miniflux.entrypoints=websecure"
        "--label=traefik.http.routers.miniflux.tls.certResolver=le"
        "--label=traefik.http.routers.miniflux.middlewares=headers"
        "--label=traefik.http.services.miniflux.loadbalancer.server.port=8080"
      ];
    };
    nextcloud = {
      image = "nextcloud:local";
      autoStart = true;
      user = "1000:100";
      dependsOn = ["mariadb" "redis"];
      environment = {
        MYSQL_HOST = "127.0.0.1";
        REDIS_HOST = "127.0.0.1";
        TRUSTED_PROXIES = "10.88.0.1/24";
        NEXTCLOUD_TRUSTED_DOMAINS = "nc.domain.com";
        MAIL_DOMAIN = "firecat53.net";
        OVERWRITEHOST = "nc.domain.com";
        OVERWRITEPROTOCOL = "https";
        OVERWRITECLIURL = "https://nc.domain.com";
        PHP_MEMORY_LIMIT = "2G";
        PHP_UPLOAD_LIMIT = "2G";
      };
      extraOptions = [
        "--device=/dev/dri"
        "--init=true"
        "--pod=cloud"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.nextcloud.rule=Host(`nc.domain.com`)"
        "--label=traefik.http.routers.nextcloud.entrypoints=websecure"
        "--label=traefik.http.routers.nextcloud.tls.certResolver=le"
        "--label=traefik.http.routers.nextcloud.middlewares=headers,nextcloud-redirectregex@file"
        "--label=traefik.http.services.nextcloud.loadbalancer.server.port=80"
        "--sysctl=net.ipv4.ip_unprivileged_port_start=80"
      ];
      volumes = ["nextcloud_config:/var/www/html" "/mnt/media:/data"];
    };
    nginx = {
      image = "nginx";
      autoStart = true;
      volumes = ["/srv/http:/var/www/misc:ro" "/srv/rss:/var/www/rss:ro"];
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.nginx.rule=Host(`domain.com`) && ((PathPrefix(`/misc`) || PathPrefix(`/rss`)))"
        "--label=traefik.http.routers.nginx.entrypoints=websecure"
        "--label=traefik.http.routers.nginx.tls.certResolver=le"
        "--label=traefik.http.routers.nginx.middlewares=headers"
        "--label=traefik.http.services.nginx.loadbalancer.server.port=8080"
      ];
    };
    podman-exporter = {
      image = "podman-exporter";
      autoStart = true;
      ports = ["9882:9882"];
      volumes = ["/run/podman/podman.sock:/run/podman/podman.sock"];
      environment = {
        CONTAINER_HOST = "unix:///run/podman/podman.sock";
      };
    };
    postgres = {
      image = "docker.io/library/postgres:15-alpine";
      autoStart = true;
      user = "70:70";
      extraOptions = ["--pod=flux"];
      volumes = ["miniflux_data:/var/lib/postgresql/data"];
    };
    qbittorrent = {
      image = "qbittorrent";
      autoStart = true;
      user = "1000:100";
      dependsOn = ["wireguard-client"];
      environment = {
        QBT_WEBUI_PORT = "8081";
      };
      extraOptions = [
        "--init=true"
        "--network=container:wireguard-client"
        "--pod=wg"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.qbittorrent.rule=Host(`qbt.domain.com`)"
        "--label=traefik.http.routers.qbittorrent.entrypoints=websecure"
        "--label=traefik.http.routers.qbittorrent.tls.certResolver=le"
        "--label=traefik.http.routers.qbittorrent.middlewares=headers"
        "--label=traefik.http.services.qbittorrent.loadbalancer.server.port=8081"
      ];
      volumes = ["qbittorrent_config:/config" "/mnt/downloads:/data"];
    };
    redis = {
      image = "docker.io/library/redis:latest";
      autoStart = true;
      user = "1000:100";
      cmd = ["redis-server" "--save" "59" "1" "--loglevel" "warning"];
      extraOptions = ["--pod=cloud"];
      volumes = ["redis_data:/data"];
    };
    samba = {
      image = "samba";
      autoStart = true;
      ports = ["137:137/udp" "138:138/udp" "139:139" "445:445"];
      volumes = [
        "samba_config:/config"
        "/mnt/downloads:/mnt/downloads"
        "/mnt/media:/mnt/media"
        "/home:/home"
      ];
    };
    plex = {
      image = "docker.io/plexinc/pms-docker:latest";
      autoStart = true;
      ports = ["32400:32400" "32410:32410" "32412:32412" "32413:32413" "32414:32414"];
      volumes = ["plex_config:/config" "/mnt/downloads:/data" "/mnt/media:/mnt/media"];
      environment = {
        TZ = "America/Los_Angeles";
        PLEX_CLAIM = "claim-sg6qnQnT5p7fB8hnFmp2";
        PLEX_UID = "1000";
        PLEX_GID = "100";
        ADVERTISE_IP = "http://192.168.1.2:32400/";
        ALLOWED_NETWORKS = "192.168.1.0/24";
      };
      extraOptions = ["--device=/dev/dri" "--init=true" "--no-healthcheck"];
    };
    radarr = {
      image = "radarr";
      autoStart = true;
      user = "1000:100";
      extraOptions = [
        "--init=true"
        "--pod=download"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.radarr.rule=Host(`radarr.domain.com`)"
        "--label=traefik.http.routers.radarr.entrypoints=websecure"
        "--label=traefik.http.routers.radarr.tls.certResolver=le"
        "--label=traefik.http.routers.radarr.middlewares=headers"
        "--label=traefik.http.services.radarr.loadbalancer.server.port=7878"
      ];
      volumes = ["radarr_config:/config" "/mnt/downloads:/data"];
    };
    sabnzbd = {
      image = "sabnzbd";
      autoStart = true;
      user = "1000:100";
      extraOptions = [
        "--init=true"
        "--pod=download"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.sabnzbd.rule=Host(`sabnzbd.domain.com`)"
        "--label=traefik.http.routers.sabnzbd.entrypoints=websecure"
        "--label=traefik.http.routers.sabnzbd.tls.certResolver=le"
        "--label=traefik.http.routers.sabnzbd.middlewares=headers"
        "--label=traefik.http.services.sabnzbd.loadbalancer.server.port=8080"
      ];
      volumes = ["sabnzbd_config:/config" "/mnt/downloads:/data"];
    };
    socks-proxy = {
      image = "socks-proxy";
      autoStart = true;
      dependsOn = ["wireguard-client"];
      extraOptions = [
        "--pod=wg"
        "--network=container:wireguard-client"
      ];
    };
    sonarr = {
      image = "sonarr";
      autoStart = true;
      user = "1000:100";
      extraOptions = [
        "--init=true"
        "--pod=download"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.sonarr.rule=Host(`sonarr.domain.com`)"
        "--label=traefik.http.routers.sonarr.entrypoints=websecure"
        "--label=traefik.http.routers.sonarr.tls.certResolver=le"
        "--label=traefik.http.routers.sonarr.middlewares=headers"
        "--label=traefik.http.services.sonarr.loadbalancer.server.port=8989"
      ];
      volumes = ["sonarr_config:/config" "/mnt/downloads:/data"];
    };
    syncthing = {
      image = "syncthing";
      autoStart = true;
      ports = ["22000:22000" "22000:22000/udp" "21027:21027/udp"];
      volumes = [
        "syncthing_config:/config"
        "/mnt/media:/mnt/media"
        "/srv:/srv"
        "/var/backups:/var/backups"
      ];
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.syncthing.rule=Host(`syncthing.domain.com`)"
        "--label=traefik.http.routers.syncthing.entrypoints=websecure"
        "--label=traefik.http.routers.syncthing.tls.certResolver=le"
        "--label=traefik.http.routers.syncthing.middlewares=headers"
        "--label=traefik.http.services.syncthing.loadbalancer.server.port=8384"
      ];
    };
    traefik = {
      image = "docker.io/library/traefik:latest";
      autoStart = true;
      ports = ["80:80" "443:443"];
      volumes = ["traefik_config:/etc/traefik" "/run/podman/podman.sock:/var/run/docker.sock"];
      extraOptions = [
        "--add-host=host.docker.internal:10.88.0.1"
        "--env-file=/root/.cloudflare"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.traefik-http.rule=Host(`monitor.domain.com`)"
        "--label=traefik.http.routers.traefik-http.entrypoints=web"
        "--label=traefik.http.routers.traefik-https.rule=Host(`monitor.domain.com`)"
        "--label=traefik.http.routers.traefik-https.entrypoints=websecure"
        "--label=traefik.http.routers.traefik-https.service=api@internal"
        "--label=traefik.http.routers.traefik-https.tls.certResolver=le"
        "--label=traefik.http.routers.traefik-https.middlewares=auth,headers"
        "--label=traefik.http.middlewares.auth.basicauth.users=firecat53:$apr1$xxxxxx"
        "--label=traefik.http.middlewares.headers.headers.browserxssfilter=true"
        "--label=traefik.http.middlewares.headers.headers.contenttypenosniff=true"
        "--label=traefik.http.middlewares.headers.headers.forcestsheader=true"
        "--label=traefik.http.middlewares.headers.headers.framedeny=true"
        "--label=traefik.http.middlewares.headers.headers.customframeoptionsvalue=SAMEORIGIN"
        "--label=traefik.http.middlewares.headers.headers.sslhost=domain.com"
        "--label=traefik.http.middlewares.headers.headers.sslredirect=true"
        "--label=traefik.http.middlewares.headers.headers.stsincludesubdomains=true"
        "--label=traefik.http.middlewares.headers.headers.stspreload=true"
        "--label=traefik.http.middlewares.headers.headers.stsseconds=315360000"
      ];
    };
    transmission = {
      image = "transmission";
      autoStart = true;
      ports = ["9091:9091" "30020:30020" "30020:30020/udp"];
      volumes = ["transmission_config:/config" "/mnt/downloads:/data"];
      user = "1000:100";
      extraOptions = [
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.transmission.rule=Host(`transmission.domain.com`)"
        "--label=traefik.http.routers.transmission.entrypoints=websecure"
        "--label=traefik.http.routers.transmission.tls.certResolver=le"
        "--label=traefik.http.routers.transmission.middlewares=auth-transmission"
        "--label=traefik.http.middlewares.auth-transmission.basicauth.users=firecat53:$apr1$xxxxxx"
        "--label=traefik.http.services.transmission.loadbalancer.server.port=9091"
      ];
    };
    unifi = {
      image = "unifi";
      autoStart = true;
      volumes = ["unifi_config:/config"];
      ports = ["3478:3478/udp" "6789:6789" "8080:8080" "8843:8843" "8880:8880" "10001:10001/udp"];
      extraOptions = [
        "--init=true"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.unifi.rule=Host(`unifi.domain.com`)"
        "--label=traefik.http.routers.unifi.entrypoints=websecure"
        "--label=traefik.http.routers.unifi.tls.certResolver=le"
        "--label=traefik.http.routers.unifi.middlewares=headers"
        "--label=traefik.http.services.unifi.loadbalancer.server.port=8443"
        "--label=traefik.http.services.unifi.loadbalancer.server.scheme=https"
        "--label=traefik.http.services.unifi.loadbalancer.passhostheader=true"
      ];
    };
    vaultwarden = {
      image = "vaultwarden";
      autoStart = true;
      user = "1000:100";
      volumes = ["vaultwarden_data:/data"];
      environment = {
        DOMAIN = "https://bw.domain.com";
        SMTP_HOST = "smtp.domain.com";
        SMTP_FROM = "from@domain.com";
        SMTP_PORT = "587";
        SMTP_SECURITY = "starttls";
        SMTP_USERNAME = "me@domain.com";
        SMTP_PASSWORD = "xxxxxx";
        ROCKET_PORT = "8080";
      };
      extraOptions = [
        "--init=true"
        "--label=traefik.enable=true"
        "--label=traefik.http.routers.vaultwarden.rule=Host(`bw.domain.com`)"
        "--label=traefik.http.routers.vaultwarden.entrypoints=websecure"
        "--label=traefik.http.routers.vaultwarden.tls.certResolver=le"
        "--label=traefik.http.routers.vaultwarden.middlewares=headers"
        "--label=traefik.http.services.vaultwarden.loadbalancer.server.port=8080"
      ];
    };
    wireguard-client = {
      image = "wireguard-client";
      autoStart = true;
      volumes = ["wireguard_config:/etc/wireguard"];
      environment = {
        LOCAL_NETWORKS = "10.1.1.0/24,192.168.1.0/24";
      };
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--cap-add=NET_RAW"
        "--dns=172.16.0.1"
        "--pod=wg"
      ];
    };
  };
  # For wireguard-client
  boot.kernel.sysctl."net.ipv4.conf.all.src_valid_mark" = 1;
}
