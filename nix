#!/usr/bin/env python3
import os, subprocess, sys
argv = sys.argv

def checkArgv(condidtion):
    for arg in argv:
        if arg == condidtion:
            return True
    return False


def returnOption(condidtion):
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
    def find_in_store(lib):
        cmd = "find /nix/store/ | grep {}".format(lib)
        return subprocess.getoutput(cmd).splitlines()[0]

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

    print("Find libraries. This might take a while")
    binary = argv[-1]

    if os.path.isfile(binary) != True:
        print("Please specify a valid file")
        sys.exit(1)

    libraries = subprocess.getoutput("ldd {}".format(binary)).splitlines()

    lib_paths = [".", "/run/current-system/sw/lib"]

    for lib in libraries:
        lib = lib.strip('\t')
        if lib.find("ld-linux") != -1:
            libdep = lib.split(' ')[0]
            interpreter_start = libdep.find("ld")
            interpreter_path = find_in_store(libdep[interpreter_start:])
        if lib.find("not") != -1:
            libdep = libraries[1].split(' ')[0]
            lib_path = find_in_store(libdep)
            lib_paths.append(os.path.dirname(lib_path))

    rpath = ':'.join(lib_paths)

    print("Patching interpreter")
    os.system("patchelf --set-interpreter {} {}".format(interpreter_path, binary))
    print("Patching rpath")
    os.system("patchelf --set-rpath {} {}".format(rpath, binary))

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
    patch               Patches a prebuilt binary to run on nixos

Patch Options
    -gc [true/false]    Whether to collect garbage or not
""".format(argv[0])

if len(argv) <= 1 or checkArgv("help") == True:
    print(help)
else:
    main()
