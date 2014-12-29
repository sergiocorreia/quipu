# -*- coding: utf-8 -*-

"""
build
~~~~~~~~~~~~~~~

Puts together all files for estdb.ado and place them in the ../package folder
You need to run this from the /build folder

Note: Wrote in Python 2.7 but should work with Python 3.

Note: assert_msg loaded with git_submodules from externals/stata-misc/assert_msg.ado 
(better than just copy-pasting, see
http://stackoverflow.com/questions/2140985/how-to-set-up-a-git-project-to-use-an-external-repo-submodule

"""

# -------------------------------------------------------------
# Imports
# -------------------------------------------------------------

from __future__ import print_function
from __future__ import division

import os, time, re, shutil

# Constants
fn = "estdb.ado"
source_path = u"../source"
server_path = u"../package"

print("parsing file <{}>".format(fn))
full_fn = os.path.join(source_path, fn)
data = open(full_fn, "rb").read()

# Add includes
includes = re.findall('^\s*include "([^"]+)"', data, re.MULTILINE)
for include in includes:
    print("    parsing include <{}>".format(include))
    full_include = os.path.join(source_path, include)
    include_data = open(full_include, "rb").read()
    data = data.replace(u'include "{}"'.format(include), '\r\n' + include_data)

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
    new_fh.write(data)

# Update reghdfe.pkg
print("updating date in estdb.pkg")
full_pkg = os.path.join(source_path, u"estdb.pkg")
pkg = open(full_pkg, "rb").read()
today = time.strftime("%Y%m%d")
pkg = re.sub(ur'Distribution-Date: \d+', ur'Distribution-Date: ' + today, pkg)
open(full_pkg, 'wb').write(pkg)
shutil.copy(full_pkg, os.path.join(server_path, u"estdb.pkg"))

# Copy
print("Copying misc files...")
fns = ["estdb.sthlp", "stata.toc", "estdb-associate-template.reg.ado", "estdb-top.tex.ado", "estdb-bottom.tex.ado"]
for fn in fns:
	shutil.copy(os.path.join(source_path, fn), os.path.join(server_path, fn))

# Copy the .def file as .def.ado so Stata installs it w/out the need for the -all- option
shutil.copy(os.path.join(source_path, "estout_estdb.def"), os.path.join(server_path, "estout_estdb.def.ado"))

print("Done!")
