{config, pkgs, lib, ...}:
let
  hasNvidiaDevice = config.hardware.nvidia-container-toolkit.enable or false;
  cfg = config.host.partition;
in
{
  fonts.fontconfig.enable = true;

  # programs.bash.shellAliases = {
  #   llm= "xdg-open http://localhost:3000";
  #   llm-search = "xdg-open https://ollama.com/library";
  #   llm-pull = "docker exec -it ollama ollama pull";
  #   llm-rm = "docker exec -it ollama ollama rm";
  #   llm-list = "docker exec -it ollama ollama list";
  # };

  
  # # Ensure directories exist
  # systemd.tmpfiles.rules = [
  #   "d ${cfg.persist.path}/llm/ollama 0755 root root -"
  #   "d ${cfg.persist.path}/llm/open-webui 0755 root root -"
  # ];

  # # Create Docker network before containers start
  # systemd.services.init-ollama-network = {
  #   description = "Create ollama Docker network";
  #   after = [ "docker.service" ];
  #   wantedBy = [ "multi-user.target" ];
    
  #   serviceConfig = {
  #     Type = "oneshot";
  #     RemainAfterExit = true;
  #   };
    
  #   script = ''
  #     # Check if network exists, create if it doesn't
  #     ${pkgs.docker}/bin/docker network inspect ollama-network >/dev/null 2>&1 || \
  #       ${pkgs.docker}/bin/docker network create ollama-network
  #   '';
  # };

  # virtualisation.oci-containers = {
  #   backend = "docker";
    
  #   containers = {
  #     ollama = {
  #       image = "ollama/ollama:latest";
  #       autoStart = true;
  #       ports = [ "127.0.0.1:11434:11434" ];
  #       volumes = [ "${cfg.persist.path}/llm/ollama:/root/.ollama" ];
        
  #       environment = {
  #         OLLAMA_HOST = "0.0.0.0:11434";
  #       };
        
  #       extraOptions = [
  #         "--network=ollama-network"
  #       ] ++ lib.optionals hasNvidiaDevice [
  #         "--device=nvidia.com/gpu=all"
  #         "--security-opt=label=disable"
  #       ];
  #     };

  #     open-webui = {
  #       image = "ghcr.io/open-webui/open-webui:main";
  #       autoStart = true;
  #       ports = [ "127.0.0.1:3000:8080" ];
  #       volumes = [ "${cfg.persist.path}/llm/open-webui:/app/backend/data" ];
        
  #       environment = {
  #         OLLAMA_BASE_URL = "http://ollama:11434";
  #         WEBUI_AUTH = "False";
  #       };
        
  #       dependsOn = [ "ollama" ];
        
  #       extraOptions = [
  #         "--network=ollama-network"
  #       ];
  #     };
  #   };
  # };

  # # Ensure containers start after network is created
  # systemd.services.docker-ollama = {
  #   after = [ "init-ollama-network.service" ];
  #   requires = [ "init-ollama-network.service" ];
  # };

  # systemd.services.docker-open-webui = {
  #   after = [ "init-ollama-network.service" ];
  #   requires = [ "init-ollama-network.service" ];
  # };

}
