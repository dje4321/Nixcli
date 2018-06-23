#!/usr/bin/env python3
import os, subprocess, sys
argv = sys.argv

def main():
    if argv[1] == "install":
        install()
    elif argv[1] == "uninstall":
        uninstall()
    elif argv[1] == "search":
        search()
    elif argv[1] == "update":
        update()
    elif argv[1] == "patch":
        patch()

def install():
    if len(argv) <= 2:
        print("{} install PROGRAM".format(argv[0]))
        sys.exit()
    else:
        os.system("nix-env -i {}".format(argv[2]))

def uninstall():
    if len(argv) <= 2:
        print("{} uninstall PROGRAM".format(argv[0]))
        sys.exit()
    else:
        os.system("nix-env -e {}".format(argv[2]))

def search():
    if len(argv) <= 2:
        print("{} patch PROGRAM".format(argv[0]))
        sys.exit()
    else:
        os.system("nix-env -qa --description | grep --color=auto {}".format(argv[2]))

def update():
    if len(argv) <= 2:
        if input("Do you wish to update everything? [Y/n]:").lower() != "n":
            os.system('nix-env -u "*"')
    else:
        os.system("nix-env -u {}".format(argv[2]))

def patch():
    lib_path = []
    if os.system("patchelf >/dev/null 2>/dev/null") != 256: # See if patchelf is installed
        print("Please install patchelf")
        sys.exit()
    if len(argv) <= 2: # Check if a file name was passed
        print("{} patch FILENAME".format(argv[0]))
        sys.exit()

    libary = subprocess.getoutput("ldd {}".format(argv[2])).split('\n') #Get output of libraries of the file

    for i in range(0,len(libary)): # Iterate over the list of libraries
        libary[i] = libary[i].strip('\t') # Strip the leading tab off of the string

        if libary[i].count("ld-linux") >= 1: # Check if the library is the interpreter
            interpreter = libary[i].split(" ")[0].find("ld") # Find the postition of the interpreter
            interpreter_path = subprocess.getoutput("find /nix/store/ | grep {}".format( libary[i].split(" ")[0][interpreter:] )).split('\n')[0] # Find a interpreter

        if libary[i].count("not") >= 1: # Check if the library isnt found
            lib_path.append(os.path.dirname( subprocess.getoutput("find /nix/store/ | grep {}".format( libary[i].split(" ")[0]) ).split('\n')[0]) ) # Get the path of the found library

    rpath = ".:/run/current-system/sw/lib" # Set the default rpath
    for x in range(0,len(lib_path)): # Iterate over the found paths
        rpath += ":{}".format(lib_path[x]) # add the found paths to the rpaths

    print("Patching interpreter")
    os.system("patchelf --set-interpreter {} {}".format(interpreter_path,argv[2])) # Patch the interpreter to the one found
    print("Patching rpath")
    os.system("patchelf --set-rpath {} {}".format(rpath,argv[2])) # Patch the rpaths to the found libarys

################################################################################
"""
argv[0]
"""

help = """{}

Avalible Commands
    install         Installs a program
    uninstall       Removes a program
    search          Searchs for a program
    update          Updates a package
    patch           Patches a prebuilt binary to run on nixos
""".format(argv[0])

if len(argv) <= 1:
    print(help)
else:
    main()
