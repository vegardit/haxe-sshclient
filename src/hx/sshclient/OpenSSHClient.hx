/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.sshclient;

import sys.io.Process;
import hx.concurrent.thread.BackgroundProcess;
import hx.files.File;
import hx.sshclient.SSHClient.Secret;
import hx.sshclient.SSHClient.SSHClientBuilder;
import hx.sshclient.internal.Either3;
import hx.sshclient.internal.MiscUtils.lazyNonNull;
import hx.sshclient.internal.OS;

using hx.strings.Strings;

@:access(hx.sshclient.OpenSSHClientBuilder)
function builder():OpenSSHClientBuilder
   return new OpenSSHClientBuilder();


enum OpenSSHHostKeyChecking {
   /** only accept connections to hosts with already known host keys */
   Strict;

   /** accept connections to hosts with already known host keys or new hosts */
   AcceptNew;

   /** INSECURE: accept connections to all hosts ignoring host keys */
   Off;
}


/**
 * Uses OpenSSH to communicate with remote hosts.
 */
@:allow(hx.sshclient.OpenSSHClientBuilder)
class OpenSSHClient extends SSHClient {

   public var executable(default, null):File = lazyNonNull();
   public var hostKeyChecking(default, null):OpenSSHHostKeyChecking = Strict;


   function new() {
      super();
   }


   public function execute(cmd:String):BackgroundProcess {
      /*
       * build openssh argument list
       */
      final args:Array<Any> = [
         username + "@" + hostname,
         "-p",
         port,
         "-o",
         "StrictHostKeyChecking=" + switch (hostKeyChecking) {
            case Strict: "yes";
            case AcceptNew: "accept-new";
            case Off: "no";
         },
         "-o",
         "UpdateHostKeys=yes",
         "-" + (agentForwarding ? "A" : "a")
      ];
      switch (secret) {
         case AuthenticationAgent:
         // nothing to do
         case IdentityFile(file):
            args.push("-o");
            args.push("IdentitiesOnly=yes");
            args.push("-i");
            args.push(switch (file.value) {
               case a(path): path;
               case b(file): file;
               case c(string): string;
            });
         case Password(_):
            // args.push("-o");
            // args.push("PreferredAuthentications=password");
            // args.push("-o");
            // args.push("PubkeyAuthentication=no");
            throw "Password authentication is not supported with OpenSSH!";
      }
      if (compression)
         args.push("-C");

      args.push(cmd);
      /*
       * execute command via openssh
       */
      return new BackgroundProcess(executable.toString(), args);
   }
}

@:allow(hx.sshclient.OpenSSHClient)
class OpenSSHClientBuilder extends SSHClientBuilder<OpenSSHClient, OpenSSHClientBuilder> {

   function new() {
      super();

      this.client = new OpenSSHClient();
   }


   override //
   public function build():OpenSSHClient {
      super.build();
      this.clientBuilt = false;

      if (client.executable == null) {
         final sshExe = locateOpenSSH();
         if (sshExe != null) {
            client.executable = sshExe;
         } else {
            throw "OpenSSH client not found on PATH!";
         }
      } else if (!client.executable.path.isFile()) {
         throw 'Specified executable [${client.executable}] does not exist or is not a regular file!';
      }

      this.clientBuilt = true;
      return this.client;
   }


   public function withExecutable(value:Either3<haxe.io.Path, File, String>):OpenSSHClientBuilder {
      switch (value.value) {
         case a(path): client.executable = File.of(path.toString());
         case b(file): client.executable = file;
         case c(string): client.executable = File.of(string);
      }
      return this;
   }


   override //
   public function withSecret(value:Secret):OpenSSHClientBuilder {
      switch (value) {
         case Password(_): throw "Password authentication is not supported with OpenSSH!";
         default:
      }
      client.secret = value;
      return cast this;
   }


   public function withHostKeyChecking(value:OpenSSHHostKeyChecking):OpenSSHClientBuilder {
      client.hostKeyChecking = value;
      return this;
   }
}


function locateOpenSSH():Null<File> {
   var p:Process;
   switch (OS.current) {
      case Windows:
         var sshExe = File.of("C:\\Windows\\System32\\OpenSSH\\ssh.exe");
         if (sshExe.path.exists())
            return sshExe;

         p = new Process("WHERE", ["ssh.exe"]);

      case Linux, Mac: p = new Process("which", ["ssh"]);
      default: return null;
   }
   if (p.exitCode() != 0)
      return null;
   var sshExe = File.of(p.stdout.readLine());
   // check if ssh command actually is OpenSSH
   p = new Process(sshExe.toString(), ["-V"]);
   if (p.exitCode() == 0 && p.stderr.readLine().indexOf("OpenSSH") > -1) {
      return sshExe;
   }
   trace('WARNING: ${sshExe} is not an OpenSSH client binary.');
   return null;
}
