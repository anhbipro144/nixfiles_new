let
  linux = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILuFdFDnnC69P63vcyxfEbUrjfpL/1fHTIjzUAIop46f agenix-linux";
in {
  "neo_ONE_key.age".publicKeys = [ linux ];
  "neo_personal_key.age".publicKeys = [ linux ];
  "neo_ubuntu.pem.age".publicKeys = [ linux ];
}
