/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.sshclient.internal;

import haxe.macro.*;

/**
 * <b>IMPORTANT:</b> This class it not part of the API. Direct usage is discouraged.
 */
@:noDoc @:dox(hide)
@:noCompletion
final class Macros {

   static var __static_init = {
      #if (haxe_ver < 4.2)
         throw 'ERROR: Haxe 4.2 or higher is required!';
      #end
      final def = Context.getDefines();
      final supportedTargets = ["cpp", "cs", "hl", "java", "jvm", "neko", "python"];
      final targetName = def.get("target.name");
      if (!supportedTargets.contains(targetName)) {
         throw 'ERROR: Unsupported Haxe target [${targetName}]! Supported are ${supportedTargets}';
      }
   };


   macro //
   public static function addDefines() {
      final def = Context.getDefines();
      if (def.exists("java") && !def.exists("jvm")) {
         trace("[INFO] Setting compiler define 'java_src'.");
         Compiler.define("java_src");
      }
      return macro {}
   }


   macro //
   public static function configureNullSafety() {
      haxe.macro.Compiler.nullSafety("hx.sshclient", StrictThreaded);
      return macro {}
   }
}
