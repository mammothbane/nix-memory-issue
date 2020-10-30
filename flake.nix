{
  description = "it breaks";

  inputs = {
    cachix = {
      url = "github:cachix/cachix/master";
      flake = false;
    };
  };

  outputs = { self, ... } @ inputs: {
    defaultPackage.x86_64-linux = import inputs.cachix;
  };
}
