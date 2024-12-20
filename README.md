# haxe-sshclient

[![Build Status](https://github.com/vegardit/haxe-sshclient/workflows/Build/badge.svg "GitHub Actions")](https://github.com/vegardit/haxe-sshclient/actions?query=workflow%3A%22Build%22)
[![Release](https://img.shields.io/github/release/vegardit/haxe-sshclient.svg)](http://lib.haxe.org/p/haxe-sshclient)
[![License](https://img.shields.io/github/license/vegardit/haxe-sshclient.svg?label=license)](#license)
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.1%20adopted-ff69b4.svg)](CODE_OF_CONDUCT.md)

1. [What is it?](#what-is-it)
1. [Installation](#installation)
1. [Using the SSH client](#usage)
1. [Using the latest code](#latest)
1. [License](#license)


## <a name="what-is-it"></a>What is it?

A [haxelib](http://lib.haxe.org/documentation/using-haxelib/) that provides a basic SSH client to execute commands on remote system. It uses a pre-installed
[OpenSSH](https://www.openssh.com/), [Putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/), or [Kitty](https://www.9bis.net/kitty/index.html) client under the hood.

All classes are located in the package `hx.sshclient` or below.

### Requirements/Limitations

- **Haxe Version:** 4.2.0 or higher
- **Supported Targets:** C++, C#, Neko, HashLink, Java/JVM, Python
- **Supported Operating Systems:** Linux, MacOS, Windows
- **Preinstalled software:** one of the following SSH clients must be installed:
  - Linux/MacOS: OpenSSH (ssh), [Putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/) (plink)
  - Windows: OpenSSH (ssh.exe), [Putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/) (plink.exe), [Kitty](https://www.9bis.net/kitty/index.html) (klink.exe)
- **Password-based authentication** is only supported when using Putty/Kitty.


## <a name="installation"></a>Installation

1. MacOS, Linux and Windows 10 or higher have OpenSSH client preinstalled. If you want to use password based authentication install Putty or Kitty client:
   - MacOS: `brew install putty`
   - Debian/Ubuntu Linux: `sudo apt-get install -y putty-tools`
   - RedHat Linux: `sudo yum install putty`
   - Windows:
     - Putty client: download **plink.exe** from https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html
     - Kitty client: download **klink.exe** from https://www.9bis.net/kitty/index.html#!pages/download.md

1. Install the library via haxelib using the command:
    ```
    haxelib install haxe-sshclient
    ```

1. Use the library in your Haxe project:

   - for [OpenFL](http://www.openfl.org/)/[Lime](https://github.com/openfl/lime) projects add `<haxelib name="haxe-sshclient" />` to your [project.xml](http://www.openfl.org/documentation/projects/project-files/xml-format/)
   - for free-style projects add `-lib haxe-sshclient`  to `your *.hxml` file or as command line option when running the [Haxe compiler](http://haxe.org/manual/compiler-usage.html)


## <a name="usage"></a>Using the SSH client

### Configuring a Putty/Kitty based SSH client

The following code creates an SSH client backed by Putty/Kitty with default settings that:
- either uses Putty or Kitty depending on which client was found on the system path - or fails if neither is found
- uses HostKeyChecking strategy `Strict`, i.e. only connects to hosts that are already known
- connects to port 22
```haxe
import hx.sshclient.PuttySSHClient;
//...
var sshClient = PuttySSHClient.builder()
   .withHostname("myhost")
   .withUsername("myuser")
   .withSecret(Password("mypassword"))
   .build();
```

The SSH client can be further configured:
```haxe
import hx.sshclient.PuttySSHClient;
//...
var sshClient = PuttySSHClient.builder()
   .withHostname("myhost")
   .withPort(2222) // use a different port
   .withUsername("myuser")
   .withSecret(IdentityFile("C:\\Users\\myser\\mykey.ppk")) // use a private key for autentication
   .withHostKeyChecking(AcceptNew) // allow connection to new hosts but prevent connections to known hosts with mismatching host keys
   .withExecutable("C:\\apps\\network\\putty\\plink.exe") // specify the client binary to be used
   .build();
```

### Configuring an OpenSSH based SSH client
The following code creates an SSH client backed by OpenSSH with default settings that:
- either uses an OpenSSH client or fails if not found on the system path
- uses HostKeyChecking strategy `Strict`, i.e. only connects to hosts that are already known
- connects to port 22
```haxe
import hx.sshclient.OpenSSHClient;
//...
var sshClient = OpenSSHClient.builder()
   .withHostname("myhost")
   .withUsername("myuser")
   .withSecret(IdentityFile("/home/myuser/ssh/id_rsa")) // use a private key for authentication
   .build();
```

The SSH client can be further configured:
```haxe
import hx.sshclient.OpenSSHClient;
//...
var sshClient = PuttySSHClient.builder()
   .withHostname("myhost")
   .withPort(2222) // use a different port
   .withUsername("myuser")
   .withHostKeyChecking(AcceptNew) // allow connection to new hosts but prevent connections to known hosts with mismatching host keys
   .withExecutable("/opt/openssh/bin/ssh") // specify the client binary to be used
   .build();
```

### Executing a remote command via SSH

Once you have created an ssh client object you can execute remote commands:
```haxe
var cmd = sshClient.execute("whoami");
cmd.awaitSuccess(5000); // wait 5 seconds for a successful response, throws an exception otherwise
var output = cmd.stdout.readAll().trim(); // retrieve the output of the executed command
trace('result: ${output}');
```


## <a name="latest"></a>Using the latest code

### Using `haxelib git`

```batch
haxelib git haxe-sshclient https://github.com/vegardit/haxe-sshclient main D:\haxe-projects\haxe-sshclient
```

###  Using Git

1. check-out the main branch
    ```batch
    git clone https://github.com/vegardit/haxe-sshclient --branch main --single-branch D:\haxe-projects\haxe-sshclient
    ```

2. register the development release with Haxe
    ```batch
    haxelib dev haxe-sshclient D:\haxe-projects\haxe-sshclient
    ```


## <a name="license"></a>License

All files are released under the [Apache License 2.0](LICENSE.txt).

Individual files contain the following tag instead of the full license text:
```
SPDX-License-Identifier: Apache-2.0
```
