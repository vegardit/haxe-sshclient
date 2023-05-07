/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.sshclient;

import hx.files.Path;
import hx.files.File;
import hx.sshclient.internal.Either3;
import hx.sshclient.internal.MiscUtils.lazyNonNull;
import hx.concurrent.thread.BackgroundProcess;

using hx.strings.Strings;

enum Secret {
   AuthenticationAgent();
   IdentityFile(file:Either3<haxe.io.Path, hx.files.File, String>);

   /** may not be supported by all SSH Connectors (e.g. OpenSSHConnector) */
   Password(password:String);
}


@:allow(hx.sshclient.SSHClientBuilder)
abstract class SSHClient {

   public var hostname(default, null):String = lazyNonNull();
   public var port(default, null):Int = 22;
   public var username(default, null):String = lazyNonNull();
   public var secret(default, null):Secret = lazyNonNull();
   //
   public var agentForwarding(default, null):Bool = false;
   public var compression(default, null):Bool = false;


   inline function new() {
   }


   public abstract function execute(cmd:String):BackgroundProcess;


   public function toString():String {
      @:nullSafety(Off)
      return '${Type.getClassName(Type.getClass(this))}[${username}@${hostname}:${port},Secret(${secret.getName()})]';
   }
}


#if !cs abstract #end // see https://github.com/HaxeFoundation/haxe/issues/10930


class SSHClientBuilder<T:SSHClient, This:SSHClientBuilder<T, This>> {

   var client:T = lazyNonNull();
   var clientBuilt = false;


   inline function new() {
   }


   public function build():T {
      if (clientBuilt)
         throw "Already built!";
      if (client.hostname.isBlank())
         throw "[hostname] must be set";
      if (client.port < 0 || client.port > 65535)
         throw '[port] ${client.port} not in range 0-65535';
      if (client.username.isBlank())
         throw "[username] must be set";
      if (client.secret == null)
         throw "[secret] must be set";
      switch (client.secret) {
         case AuthenticationAgent: // nothing to do
         case IdentityFile(file):
            {
               final path = switch (file.value) {
                  case a(p): Path.of(p.toString());
                  case b(f): f.path;
                  case c(v): Path.of(v);
               }
               if (!path.isFile())
                  throw '[secret.identityFile] "$file" does not exist or is not a regular file';
            }
         case Password(pw): if (Strings.isBlank(pw)) throw "[secret.password] must be set";
      }
      clientBuilt = true;
      return client;
   }


   /**
    * Enable/disable SSH agent forwarding.
    *
    * Default: false (disabled)
    */
   public function withAgentForwarding(value:Bool):This {
      client.agentForwarding = value;
      return cast this;
   }

   /**
    * Enable/disable compression.
    *
    * Default: false (disabled)
    */
   public function withCompression(value:Bool):This {
      client.compression = value;
      return cast this;
   }

   public function withHostname(value:String):This {
      client.hostname = value;
      return cast this;
   }


   public function withPort(value:Int):This {
      client.port = value;
      return cast this;
   }


   public function withSecret(value:Secret):This {
      client.secret = value;
      return cast this;
   }


   public function withUsername(value:String):This {
      client.username = value;
      return cast this;
   }
}
