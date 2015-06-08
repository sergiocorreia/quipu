# -*- coding: utf-8 -*-

"""
build
~~~~~~~~~~~~~~~

Puts together all files for quipu.ado and place them in the ../package folder
You need to run this from the /build folder

Note: Requires Python 3.x

Note: assert_msg loaded with git_submodules from externals/stata-misc/assert_msg.ado 
(better than just copy-pasting, see
http://stackoverflow.com/questions/2140985/how-to-set-up-a-git-project-to-use-an-external-repo-submodule

To do a quick test w/out going through github, run:
cap ado uninstall quipu
net from D:\Github\quipu\package
net install quipu
"""

# -------------------------------------------------------------
# Imports
# -------------------------------------------------------------
import os, time, re, shutil

# Change the working dir (our paths are relative to the build/ folder)
os.chdir(os.path.split(__file__)[0])

# Constants
source_path = "../source"
server_path = "../package"
fns = ["quipu.ado", "quipu_export.ado"]

# Update the main ADO files
for fn in fns:
    print("parsing file <{}>".format(fn))
    full_fn = os.path.join(source_path, fn)
    data = open(full_fn, "rb").read().decode()

    # Add includes
    includes = re.findall('^\s*include "([^"]+)"', data, re.MULTILINE)
    for include in includes:
        print("    parsing include <{}>".format(include))
        full_include = os.path.join(source_path, include)
        include_data = open(full_include, "rb").read().decode()
        data = data.replace('include "{}"'.format(include), '\r\n' + include_data)

    # Remove cap drops
    capdrops = re.findall('\s^\s*cap pr drop [a-zA-Z0-9_]+\s*$', data, re.MULTILINE)
    for capdrop in capdrops:
        data = data.replace(capdrop, "")        
    capdrops = re.findall('\s^\s*capture program drop [a-zA-Z0-9_]+\s*$', data, re.MULTILINE)
    for capdrop in capdrops:
        data = data.replace(capdrop, "")        

    # Save
    new_fn = os.path.join(server_path, fn)
    with open(new_fn, 'wb') as new_fh:
        new_fh.write(data.encode())

# Update reghdfe.pkg
print("updating date in quipu.pkg")
full_pkg = os.path.join(source_path, "quipu.pkg")
pkg = open(full_pkg, "rb").read().decode()
today = time.strftime("%Y%m%d")
pkg = re.sub(r'Distribution-Date: \d+', r'Distribution-Date: ' + today, pkg)
open(full_pkg, 'wb').write(pkg.encode())
shutil.copy(full_pkg, os.path.join(server_path, "quipu.pkg"))

# Copy
print("Copying misc files...")
fns = ["quipu.sthlp", "stata.toc", "quipu-associate-template.reg.ado",
    "quipu-top.tex.ado", "quipu-bottom.tex.ado", 
    "quipu-top.html.ado", "quipu-bottom.html.ado"]

for fn in fns:
    shutil.copy(os.path.join(source_path, fn), os.path.join(server_path, fn))

print("Done!")
