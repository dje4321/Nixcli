#!/usr/bin/env python3
import os, subprocess, sys
argv = sys.argv

def debugOutput(loc,var):
    if checkArgv("--trace") == True:
        print("")
        print("DEBUG:{}".format(loc))
        print("VARIABLE:{}".format(repr(var)))

def checkArgv(condidtion):
    for arg in argv:
        if arg == condidtion:
            return True
    return False


def returnOption(condidtion):
    debugOutput("returnOption():condidtion",condidtion)
    for count, arg in enumerate(argv):
        if arg == condidtion:
            return argv[count + 1]

def main():
    if argv[-2] == "install":
        install()
    elif argv[-2] == "uninstall":
        uninstall()
    elif argv[-2] == "search":
        search()
    elif argv[-2] == "update":
        update()
    elif argv[-2] == "patch":
        patch()

def install():
    if len(argv) <= 2:
        print("{} install PROGRAM".format(argv[0]))
        sys.exit()
    else:
        os.system("nix-env -i {}".format(argv[-1]))

def uninstall():
    if len(argv) <= 2:
        print("{} uninstall PROGRAM".format(argv[0]))
        sys.exit()
    else:
        os.system("nix-env -e {}".format(argv[-1]))

def search():
    if len(argv) <= 2:
        print("{} patch PROGRAM".format(argv[0]))
        sys.exit()
    else:
        os.system("nix-env -qa --description | grep --color=auto {}".format(argv[-1]))

def update():
    if len(argv) <= 2:
        if input("Do you wish to update everything? [Y/n]:").lower() != "n":
            os.system('nix-env -u "*"')
    else:
        os.system("nix-env -u {}".format(argv[-1]))

def patch():
    binary = argv[-1]
    debugOutput("patch():binary",binary)
    def find_in_store(lib):
        lib = lib.strip(" ").strip('\t')
        debugOutput("find_in_store():lib",lib)
        cmd = "find /nix/store/ . /run/current-system/sw/lib -name '{}'".format(lib)
        output = subprocess.getoutput(cmd).splitlines()

        if output == []:
            return "None"
        else:
            output = output[0]

        debugOutput("find_in_store():output",output)
        return output

    def checkGarbage():
        loop = True
        while loop == True:
            answer = input("Do you want to collect garbage? [Y/n/help] ").lower()
            if answer == "y":
                collectGarbage()
                loop = False
            if answer == "n":
                print("")
                loop = False
            if answer == "help":
                print("")
                print("Collecting garbage will help ensure old libraries are not used")

    def collectGarbage():
        os.system("nix-collect-garbage")
        print("")

    if os.system("patchelf >/dev/null 2>/dev/null") != 256:
        print("Please install patchelf")
        exit()
    if len(argv) < 3:
        print("{} patch FILENAME".format(argv[0]))
        exit()
    if os.path.isfile(binary) != True:
        print("Please specify a valid file")
        sys.exit()

    if checkArgv("-gc") == True:
        if returnOption("-gc").lower() == "true":
            collectGarbage()
    else:
        checkGarbage()

    print("Finding libraries. This might take a while")

    if os.path.isfile(binary) != True:
        print("Please specify a valid file")
        sys.exit(1)

    libraries = subprocess.getoutput("ldd {}".format(binary)).splitlines()
    debugOutput("patch():libraries",libraries)

    lib_paths = []
    missingLib = []

    for lib in libraries:
        if lib.find("ld-linux") != -1: # See if we are on the interpreter
            libdep = lib.split(' ')[0]
            interpreter_start = libdep.find("ld")
            interpreter_path = find_in_store(libdep[interpreter_start:])
            if interpreter_path == "None":
                print("Could not find the interpreter {}".format(libdep))
                sys.exit(1)
        if lib.find("not") != -1: #check for missing libraries
            libdep = libraries[1].split(' ')[0]
            lib_path = find_in_store(libdep)

            if lib_path == "None": # Check if a library was missing
                missingLib.append(libdep)
            elif lib_path != '': # Dont append a empty path
                lib_paths.append(os.path.dirname(lib_path))

    lib_paths = list(set(lib_paths)) # Remove duplicates from the found paths
    lib_paths.insert(0,"/run/current-system/sw/lib") # Add default paths to rpath
    lib_paths.insert(0,".")
    debugOutput("patch():lib_paths",lib_paths)

    rpath = ':'.join(lib_paths) # Create rpathbinary from found paths

    debugOutput("patch():interpreter_path",interpreter_path)
    print("Patching interpreter")
    os.system("patchelf --set-interpreter {} {}".format(interpreter_path, binary))

    debugOutput("patch():rpath",rpath)
    print("Patching rpath")
    os.system("patchelf --set-rpath {} {}".format(rpath, binary))

    if len(missingLib) > 0:
        missingLib = list(set(missingLib)) # Dedup the list
        print("The following libraries were missing")
        for noLib in missingLib:
            print(noLib)

################################################################################
"""
argv[0]
"""

help = """{}

Avalible Commands
    help                Displays this help message
    install             Installs a program
    uninstall           Removes a program
    search              Searchs for a program
    update              Updates a packagereter_pareter_pathth
    patch               Patches a prebuilt binary to run on nixos

Patch Options
    -gc [true/false]    Whether to collect garbage or not
""".format(argv[0])

if len(argv) <= 1 or checkArgv("help") == True:
    print(help)
else:
    main()
