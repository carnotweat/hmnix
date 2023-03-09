_:
{
  config = {
    programs.adb.enable = true;
    users.users.xameer.extraGroups = [ "adbusers" ];
  };
}
