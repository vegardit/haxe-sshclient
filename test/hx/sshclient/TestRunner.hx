/*
 * SPDX-FileCopyrightText: © Vegard IT GmbH (https://vegardit.com)
 * SPDX-FileContributor: Sebastian Thomschke, Vegard IT GmbH
 * SPDX-License-Identifier: Apache-2.0
 */
package hx.sshclient;

import hx.sshclient.internal.OS;
import hx.doctest.DocTestRunner;
import hx.files.File;
import hx.sshclient.OpenSSHClient.OpenSSHHostKeyChecking;
import hx.sshclient.PuttySSHClient.PuttySSHHostKeyChecking;

using hx.strings.Strings;

@:build(hx.doctest.DocTestGenerator.generateDocTests())
@:keep // prevent DCEing of manually created testXYZ() methods
class TestRunner extends DocTestRunner {

   public static function main() {
      final runner = new TestRunner();

      runner.runAndExit();
   }


   function testPuttyWithPassword() {
      final sshClient = PuttySSHClient.builder()
         .withHostname(getEnv("TEST_SSH_HOST"))
         .withUsername(getEnv("TEST_SSH_USER"))
         .withPort(getEnvInt("TEST_SSH_PORT"))
         .withSecret(Password(getEnv("TEST_SSH_PW")))
         .withAgentForwarding(false)
         .withCompression(false)
         .withHostKeyChecking(AcceptNewTemporary)
         .build();

      trace(sshClient);
      assertEquals(sshClient.hostname, getEnv("TEST_SSH_HOST"));
      assertEquals(sshClient.username, getEnv("TEST_SSH_USER"));
      assertEquals(sshClient.port, getEnvInt("TEST_SSH_PORT"));
      assertEquals(switch (sshClient.secret) {
         case AuthenticationAgent: "AuthenticationAgent";
         case Password(password): "Password:" + password;
         case IdentityFile(file): "IdentityFile:" + switch (file.value) {
               case a(path): path.toString();
               case b(file): file.toString();
               case c(string): string;
            };
      }, "Password:" + getEnv("TEST_SSH_PW"));
      assertEquals(sshClient.agentForwarding, false);

      assertEquals(sshClient.compression, false);
      assertEquals(sshClient.hostKeyChecking, PuttySSHHostKeyChecking.AcceptNewTemporary);

      final p = sshClient.execute("whoami");
      p.awaitSuccess(5000);

      assertEquals(p.stdout.readAll().trim(), sshClient.username);
   }


   function testPuttyWithIdentityFile() {
      final sshClient = PuttySSHClient.builder()
         .withHostname(getEnv("TEST_SSH_HOST"))
         .withUsername(getEnv("TEST_SSH_USER"))
         .withPort(getEnvInt("TEST_SSH_PORT"))
         .withSecret(IdentityFile(File.of(getEnv("TEST_SSH_KEY_PPK"))))
         .withAgentForwarding(true)
         .withCompression(true)

         .withHostKeyChecking(AcceptNew)
         .build();

      trace(sshClient);
      assertEquals(sshClient.hostname, getEnv("TEST_SSH_HOST"));
      assertEquals(sshClient.username, getEnv("TEST_SSH_USER"));
      assertEquals(sshClient.port, getEnvInt("TEST_SSH_PORT"));
      assertEquals(switch (sshClient.secret) {
         case AuthenticationAgent: "AuthenticationAgent";
         case Password(password): "Password:" + password;
         case IdentityFile(file): "IdentityFile:" + switch (file.value) {
               case a(path): path.toString();
               case b(file): file.toString();
               case c(string): string;
            };
      }, "IdentityFile:" + File.of(getEnv("TEST_SSH_KEY_PPK")));
      assertEquals(sshClient.agentForwarding, true);

      assertEquals(sshClient.compression, true);
      assertEquals(sshClient.hostKeyChecking, PuttySSHHostKeyChecking.AcceptNew);

      final p = sshClient.execute("whoami");
      p.awaitSuccess(5000);

      assertEquals(p.stdout.readAll().trim(), sshClient.username);
   }


   function testOpenSSHWithPassword() {
      try {
         OpenSSHClient.builder()
            .withSecret(Password(getEnv("TEST_SSH_PW")));
      } catch (ex:haxe.Exception) {
         assertEquals(ex.message, "Password authentication is not supported with OpenSSH!");
      }
   }


   function testOpenSSHWithIdentityFile() {
      if (OS.current == Windows) {
         // Permissions for 'test\\id_key.txt' are too open.
         return;
      }

      final sshClient = OpenSSHClient.builder()
         .withHostname(getEnv("TEST_SSH_HOST"))
         .withUsername(getEnv("TEST_SSH_USER"))
         .withPort(getEnvInt("TEST_SSH_PORT"))
         .withSecret(IdentityFile(File.of(getEnv("TEST_SSH_KEY_FILE"))))
         .withAgentForwarding(true)
         .withCompression(true)

         .withHostKeyChecking(Off)
         .build();
      assertEquals(sshClient.hostname, getEnv("TEST_SSH_HOST"));
      assertEquals(sshClient.username, getEnv("TEST_SSH_USER"));
      assertEquals(sshClient.port, getEnvInt("TEST_SSH_PORT"));
      assertEquals(switch (sshClient.secret) {
         case AuthenticationAgent: "AuthenticationAgent";
         case Password(password): "Password:" + password;
         case IdentityFile(file): "IdentityFile:" + switch (file.value) {
               case a(path): path.toString();
               case b(file): file.toString();
               case c(string): string;
            };
      }, "IdentityFile:" + File.of(getEnv("TEST_SSH_KEY_FILE")));
      assertEquals(sshClient.agentForwarding, true);

      assertEquals(sshClient.compression, true);
      assertEquals(sshClient.hostKeyChecking, OpenSSHHostKeyChecking.Off);

      trace(sshClient);
      final p = sshClient.execute("whoami");
      p.awaitSuccess(5000);

      assertEquals(p.stdout.readAll().trim(), sshClient.username);
   }


   static function getEnv(key:String):String {
      final val = std.Sys.getEnv(key);
      if (val == null)
         throw 'Required environment ${key} variable not defined!';

      return val;
   }


   static function getEnvInt(key:String):Int {
      final val = getEnv(key);
      final int = std.Std.parseInt(val);
      if (int == null)
         throw 'Value ${val} of environment variable ${key} is not a valid integer!';
      return int;
   }
}
