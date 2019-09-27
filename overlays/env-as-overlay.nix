self: super: {
  jeremy-env = super.buildEnv {
    name = "jeremy-env";
    paths = (import ./..) {};
  };
}
