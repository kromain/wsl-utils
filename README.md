# wsl-utils
A collection of scripts and utilities for developers using WSL (Windows Subsystem for Linux)

## vcvars_env_run.sh

This helper script wraps the **vcvars64.bat** script from Visual Studio to allow running build commands inside a proper build environment, with the compiler and INCLUDE/LIB envvars set up. It also works around the fact that build commands can't be passed directly to **vcvars64.bat** as arguments.

The build commands can be as simple as **nmake.exe**, or they can be complex commands with **&&** and **||** operators. The script fully supports quoting and commands/arguments with spaces.

Because the commands are pre-parsed by the script, you can use Bash-style subcommands **$()**, as well as script variables and environment variables. Those will be parsed by Bash before forwarding the command to **vcvars64.bat**.

The script also forwards the return value of the executed command from the Visual Studio CMD environment back to the caller.

### Simple example: compiling code with the VC compiler and nmake.exe

```bash
cd $BUILD_DIR

vcvars_env_run.sh nmake.exe
```

### Another simple example: building libs with vcpkg

```bash
export vcpkg_cmd="vcpkg.exe --triplet %VCPKG_DEFAULT_TRIPLET%"
export vcpkg_packages="breakpad expat libconfig tbb"

cd $VCPKG_DIR

vcvars_env_run.sh $vcpkg_cmd install $vcpkg_packages 
```

Notice the *%VCPKG_DEFAULT_TRIPLET%* on the first line, this is a CMD environment variable, which will be passed as-is to *vcvars64.bat* and expanded inside there.

### Advanced example: doing an out-of-source build with cmake.exe and nmake.exe

```bash
cd $BUILD_DIR

export build_cmd=( \
    $(wslpath -w ${CMAKE_INSTALL_DIR}/bin/cmake.exe) \
        -g "NMake Makefiles" \
        -DCMAKE_BUILD_TYPE=Release \
        $(wslpath -w ${SOURCE_DIR}/CMakeLists.txt) \
    "&&" nmake.exe \
)

vcvars_env_run.sh "${build_cmd[@]}"
```

Here we need to use a Bash-specific syntax to create our complex build command with proper quoting and forwarding of arguments with spaces to Windows' CMD shell. The way to do it is to use parentheses around **build_cmd**, then expanding the variable with **"${build_cmd[@]}"** when calling our script. This tells Bash to put quotes around every token in the variable, and properly maintain quotes for already-quoted arguments (like "NMake Makefiles" in this example).

Also notice how the **&&** operator is wrapped inside quotes. This is to prevent Bash from interpreting it as the && operator itself, but it will be parsed correctly once we're on the CMD side.

### Another advanced example: copy the redistributable C/C++ Runtime DLLs into a bin folder

```bash
export copy_cmd=( \
cd "!VCToolsRedistDir!!Platform!"
    "&&" robocopy \
        /S . \
        $(wslpath -w ${BUILD_DIR}/bin) \
        msvcp* vcruntime*
        ">NUL" \
    # robocopy reports successes via non-zero retcodes, only fail for >=8 (see https://ss64.com/nt/robocopy-exit.html)
    "||" if errorlevel 8 exit /B 1 \
)

vcvars_env_run.sh "${copy_cmd[@]}"

if [[ $? -eq 1 ]]; then
   echo "Failed to copy the VC Runtime libraries to ${BUILD_DIR}/bin! 
fi
```

In this example we use delayed CMD envvar expansion with the **!VCToolsRedistDir!!Platform!** syntax (which vcvars_env_run.sh automatically enables in the CMD shell it creates), because these variables are only set during the execution of **vcvars64.bat**, at which point our CMD command is already parsed. So this is how we can extract them.

We also use the ">NUL" argument to discard the robocopy command output, which has to be quoted just like "&&" and "||", also to prevent Bash from interpreting it as its own redirection flag.

Then we play a little with return codes and their forwarding to show how the return code set on the CMD side gets forwarded back to the caller.
