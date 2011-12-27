# Executor

Executor aims to provide a standard interface to work with binaries outside of ruby. It provides a standard implementation of the following requirements:

* Capturing exit status and raising appropriate exception
* Redirecting stderr  
* Asynchronous callbacks
* Logging of command output
   
## Options

 * redirect_stderr - This will cause any stderr from a command to be merged to stdout 
 * raise_exceptions - This will listen for the exit code of the executed process and raise an exception if non 0
 * async - This is true by default if a block is given to Executor::command, async will create a new thread and execute the passed block upon completion of the process

 * logger - This takes an instance of logger (or an instance that implements #info) 

## Usage

### Basic

    require 'executor'
    
    Executor::command("echo 5")

### With redirection

    Executor::command("expr 5 / 0", :redirect_stderr => true)

### With one-time configuration

    Executor::configure(
      :raise_exceptions => false
    )

    Executor::command("expr 5 / 0")

## Special notes

 * In async mode (when block given or via explicit configuration), an exception if caught will be returned to the callback

credits: me, robgleeson@freenode
