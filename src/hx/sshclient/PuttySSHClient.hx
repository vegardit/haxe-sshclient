/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.sshclient;

import haxe.Rest;
import sys.io.Process;
import hx.concurrent.thread.BackgroundProcess;
import hx.files.File;
import hx.sshclient.SSHClient.SSHClientBuilder;
import hx.sshclient.internal.Either3;
import hx.sshclient.internal.MiscUtils.lazyNonNull;
import hx.sshclient.internal.OS;

using hx.strings.Strings;

@:access(hx.sshclient.PuttySSHClientBuilder)
function builder():PuttySSHClientBuilder
   return new PuttySSHClientBuilder();


enum PuttySSHHostKeyChecking {
   /** only accept connections to hosts with already known host keys */
   Strict();

   /**
    * accept connections to hosts with already known host keys or new hosts.
    *
    * if the host is new it's host key will be added to putty's host key register for later validation.
    */
   AcceptNew;

   /**
    * accept connections to hosts with already known host keys or new static
    *
    * if the host is new it's host key will NOT be added.
    */
   AcceptNewTemporary;

   /**
    * only accept connections to hosts matching one of the listed host keys public
    *
    * see https://the.earth.li/~sgtatham/putty/latest/htmldoc/Chapter4.html#config-ssh-kex-manual-hostkeys
    *
    * @param acceptedHostKeys e.g. "SHA256:y8VgwkQxUYGz4DMkbFSpa9QPDfINWoMlXw6r4redWZc"
    */
   AcceptOnly(acceptedHostKeys:Rest<String>);

   /** INSECURE: accept connections to all hosts ignoring host keys */
   Off;
}


/**
 * Uses plink (Putty) or klink (Kitty) to communicate with remote hosts.
 *
 * see https://the.earth.li/~sgtatham/putty/latest/htmldoc/Chapter7.html#plink
 */
@:allow(hx.sshclient.PuttySSHClientBuilder)
class PuttySSHClient extends SSHClient {

   inline static final OPT_AUTO_STORE_SSHKEY = "-auto-store-sshkey";


   public var executable(default, null):File = lazyNonNull();
   public var hostKeyChecking(default, null):PuttySSHHostKeyChecking = Strict;
   public var sessionName(default, null):Null<String> = null;


   var supportsAutoStoreSSHKeyOption = false;


   function new() {
      super();
   }


   public function execute(cmd:String):BackgroundProcess {
      /*
       * build putty argument list
       */
      final args:Array<Any> = [
         username + "@" + hostname,
         "-P",
         port,
         "-" + (agentForwarding ? "A" : "a"),
         "-ssh"
      ];
      switch (hostKeyChecking) {
         case AcceptOnly(acceptedHostKeys):
            for (acceptedHostKey in acceptedHostKeys) {
               if (acceptedHostKey.isNotBlank()) {
                  args.push("-hostkey");
                  args.push(acceptedHostKey);
               }
            }
         case AcceptNew:
            if (supportsAutoStoreSSHKeyOption) {
               args.push(OPT_AUTO_STORE_SSHKEY);
            }
         default:
      }

      switch (secret) {
         case AuthenticationAgent: args.push("-agent");
         case IdentityFile(file):
            args.push("-noagent");
            args.push("-i");
            args.push(switch (file.value) {
               case a(path): path;
               case b(file): file;
               case c(string): string;
            });
         case Password(pw):
            args.push("-noagent");
            args.push("-pw");
            args.push(pw);
      }
      if (compression)
         args.push("-C");
      if (sessionName.isNotBlank()) {
         args.push("-load");
         args.push(cast sessionName);
      }
      args.push(cmd);
      /*
       * execute command via putty
       */
      final p = BackgroundProcess.create(executable.toString(), args);
      var stdOutLine:String = "";
      var stdErrLine:String = "";
      while (p.isRunning()) {
         stdErrLine = p.stderr.previewLine(50 /*ms*/);
         if (stdErrLine.contains("\n"))
            break;
         stdOutLine = p.stdout.previewLine(50 /*ms*/);
         if (stdOutLine.isNotEmpty())
            break;
      }
      if (stdOutLine.isEmpty()) {
         if (stdErrLine.containsAny([
            "The host key is not cached for this server",
            "The server's host key is not cached"
         ])) {
            var errorMessage = p.stderr.readAll();
            if (errorMessage.contains("Store key in cache? (y/n")) {
               errorMessage = errorMessage.substringBefore("If").trim().replaceAll(Strings.NEW_LINE, " ");
               p.stdin.writeString(switch (hostKeyChecking) {
                  case AcceptNew:
                     trace('INFO: $errorMessage');
                     trace('INFO: Permanently accepting changed host key because of configured host key checking strategy [$hostKeyChecking]...');
                     "y\n";
                  case AcceptNewTemporary, Off:
                     trace('INFO: $errorMessage');
                     trace('INFO: Temporarily accepting changed host key because of configured host key checking strategy [$hostKeyChecking]...');
                     "n\n";
                  default: throw errorMessage;
               });
               p.stdin.flush();
            } else {
               p.kill();
               throw 'Cannot connect to ${hostname}: ${errorMessage.trim()}';
            }
         } else if (stdErrLine.contains("WARNING - POTENTIAL SECURITY BREACH")) {
            var errorMessage = p.stderr.readAll();
            if (errorMessage.contains("Update cached key? (y/n")) {
               errorMessage = errorMessage.substringBefore("If").trim().replaceAll(Strings.NEW_LINE, " ");
               p.stdin.writeString(switch (hostKeyChecking) {
                  case Off:
                     trace('INFO: $errorMessage');
                     trace('WARNING: Temporarily accepting changed host key because of configured host key checking strategy [$hostKeyChecking]...');
                     "n\n";
                  default: throw errorMessage;
               });
               p.stdin.flush();
            } else {
               p.kill();
               throw 'Cannot connect to ${hostname}: ${errorMessage.trim()}';
            }
         }
      }
      return p;
   }


   override //
   public function toString():String {
      return 'PuttySSHClient[${username}@${hostname}:${port},Secret(${secret.getName()}),Exe($executable)]';
   }
}

@:allow(hx.sshclient.PuttySSHClient)
class PuttySSHClientBuilder extends SSHClientBuilder<PuttySSHClient, PuttySSHClientBuilder> {

   function new() {
      super();

      this.client = new PuttySSHClient();
   }


   override //
   public function build():PuttySSHClient {
      super.build();
      this.clientBuilt = false;

      if (client.executable == null) {
         final puttyExe = locatePutty();
         if (puttyExe != null) {
            client.executable = puttyExe;
         } else {
            throw switch (OS.current) {
               case Windows: "Putty client (plink.exe or klink.exe) not found on PATH!"
                  + "Please download plink.exe from https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html "
                  + "or klink.exe from http://www.9bis.net/kitty/#!pages/download.md";
               case Linux: "Putty client (plink command) not found on PATH! Please install using 'apt-get install putty-tools' or 'yum install putty'";
               case Mac: "Putty client (plink command) not found on PATH! Please install using 'brew install putty'";
               default: "Putty client (plink command) not found on PATH! Manual installation is required.";
            }
         }
      } else if (!client.executable.path.isFile()) {
         throw 'Specified executable [${client.executable}] does not exist or is not a regular file!';
      }

      try {
         final p = new sys.io.Process(client.executable.toString(), ["--help"]);
         p.exitCode(); // await exit
         while (true) {
            if (p.stdout.readLine().contains(PuttySSHClient.OPT_AUTO_STORE_SSHKEY)) {
               client.supportsAutoStoreSSHKeyOption = true;
               break;
            }
         }
      } catch (e) {
         // ignore
      }

      this.clientBuilt = true;
      return this.client;
   }


   public function withExecutable(value:Either3<haxe.io.Path, File, String>):PuttySSHClientBuilder {
      switch (value.value) {
         case a(path): client.executable = File.of(path.toString());
         case b(file): client.executable = file;
         case c(string): client.executable = File.of(string);
      }
      return this;
   }


   public function withHostKeyChecking(value:PuttySSHHostKeyChecking):PuttySSHClientBuilder {
      client.hostKeyChecking = value;
      return this;
   }


   public function withSessionName(?value:String):PuttySSHClientBuilder {
      client.sessionName = value;
      return this;
   }
}


function locatePutty():Null<File> {
   switch (OS.current) {
      case Windows:
         var p = new Process("WHERE", ["plink.exe"]); // putty
         if (p.exitCode() == 0)
            return File.of(p.stdout.readLine());

         var p = new Process("WHERE", ["klink.exe"]); // kitty
         if (p.exitCode() == 0)
            return File.of(p.stdout.readLine());
         return null;

      case Linux, Mac:
         var p = new Process("which", ["plink"]); // putty
         if (p.exitCode() == 0)
            return File.of(p.stdout.readLine());
         return null;

      default: return null;
   }
}
