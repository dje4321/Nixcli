#!/usr/bin/env python3
import os, subprocess, sys
argv = sys.argv
binary = argv[-1]

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
    elif argv[-2] == "update" or argv[-1] == "update":
        update()
    elif argv[-1] == "upgrade":
        upgrade()
    elif argv[-2] == "patch":
        patch()

def install():
    if len(argv) <= 2:
        print("{} install PROGRAM".format(argv[0]))
        sys.exit(1)
    else:
        os.system("nix-env -i {}".format(argv[-1]))

def uninstall():
    if len(argv) <= 2:
        print("{} uninstall PROGRAM".format(argv[0]))
        sys.exit(1)
    else:
        os.system("nix-env -e {}".format(argv[-1]))

def search():
    if len(argv) <= 2:
        print("{} patch PROGRAM".format(argv[0]))
        sys.exit(1)
    else:
        os.system("nix-env -qa --description | grep --color=auto {}".format(argv[-1]))

def update():
    os.system("nix-channel --update")
    if len(argv) <= 2:
        if input("Do you wish to update everything? [Y/n]:").lower() != "n":
            os.system('nix-env -u "*"')
    else:
        os.system("nix-env -u {}".format(argv[-1]))

def upgrade():
    option = ""

    if os.getuid() != 0:
        print("Missing root permissions")
        sys.exit(1)

    os.system("nix-channel --update")

    if checkArgv("-op") == True:
        option = returnOption("-op")

    print(option)
    os.system("nixos-rebuild switch {}".format(option))

def patch():

    def findLibrary(lib):
        cmd = "find . /run/current-system/sw/lib /nix/store -name '{}'".format(lib)
        return subprocess.getoutput(cmd)

    def getPath(path):
        path = path.splitlines()
        for lib in path:
            if lib != '':
                debugOutput("DEBUG:getPath():",os.path.dirname(lib))
                return os.path.dirname(lib)
        return None

    libPaths = []

    checkGarbage()

    libraries = subprocess.getoutput("ldd {}".format(binary)) # Get all of the libraries a executable needs
    libraries = libraries.replace('\t','').splitlines() # Do some formatting

    print("Finding libraries")

    for lib in libraries: # Run over every found library
        lib = lib.split(" ")[0] # Get the library name
        if lib.find("linux-vdso") != -1: # Check if we are on linux-vdso and if so ignore it as we dont need to mess with it
            continue
        if lib.find("ld-linux") != -1: # See if we are on the interpreter
            interpreter_start = lib.find("ld")
            interpreter = lib[interpreter_start:]
            interpreter = findLibrary(interpreter).splitlines()[0]
        else:
            libPath = findLibrary(lib) # Run through the list of folders and fix the libraries
            libPath = getPath(libPath) # Get the path of found libraries
            if libPath == None:
                print("Missing:{}".format(lib))
                print("")
            else:
                print("Found:{}".format(lib))
                print("Path:{}".format(libPath))
                print("")

            libPaths.append(libPath) # Add the path to the list of known paths

    libPaths = list(set(libPaths)) # Dedup the list
    if None in libPaths: # Check if any libraries were missing and remove them
        libPaths.remove(None)

    rpath = ":".join(libPaths)

    debugOutput("patch():interpreter_path",interpreter)
    print("Patching interpreter")
    os.system("patchelf --set-interpreter {} {}".format(interpreter, binary))

    debugOutput("patch():rpath",rpath)
    print("Patching rpath")
    os.system("patchelf --set-rpath {} {}".format(rpath, binary))

def checkGarbage():
    if checkArgv("-gc") == True:
        if returnOption("-gc").lower() == "true":
            collectGarbage()
        elif returnOption("-gc").lower() == "false":
            return None
    else:
        loop = True
        while loop == True:
            ans = input("Do you want to collect garbage? [Y/n/help] ").lower()
            if ans == "y" or ans == '':
                collectGarbage()
                return None
            if ans == "n":
                print("")
                return None
            if ans == "help":
                print("Collecting garbage will help ensure old libraries are not used")
                print("")

def collectGarbage():
    print("Collecting garbage")
    os.system("nix-collect-garbage >/dev/null 2>/dev/null")
    print("")

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
    update              Updates a package
    upgrade             Upgrades the system
    patch               Patches a prebuilt binary to run on nixos

Upgrade Options
    -op                 Pass arguments to nixos-rebuild
                        ./nixcli -op "--cores 8" upgrade

Patch Options
    -gc [true/false]    Whether to collect garbage or not
""".format(argv[0])

if len(argv) <= 1 or checkArgv("help") == True:
    print(help)
    sys.exit(-127)
else:
    main()
