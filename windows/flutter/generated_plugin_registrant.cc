//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <bitsdojo_window_windows/bitsdojo_window_plugin.h>
#include <cr_flutter_libserialport/cr_flutter_libserialport_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  BitsdojoWindowPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("BitsdojoWindowPlugin"));
  CrFlutterLibserialportPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("CrFlutterLibserialportPlugin"));
}
