#!/bin/env python3
# Filename: scrub.py
# Location: Various
# Author: bgstack15@gmail.com
# Startdate: 2016-09-28
# Title: Script that Simultaneously Copies and Scrubs a Directory
# Purpose: Prepare projects for publication by removing private information like usernames and hostnames
# Package: Various
# History:
#    2016-10-03 working on batch rename files
#    2016-10-20 added not ".tgz" in source.name
# Usage:
#    Store this file with any package that gets published. Adjust scrub.txt in local directory.
#  # First line: source directory      Second line: target directory. WILL BE OVERWRITTEN!
#  /etc/ansible
#  /home/bjones/ansible.clean
#  # Rest of the lines are "OLD WORD" "NEW WORD"
#  bjones bgstack15
#  rsmith rmstack15
# Reference:
#    http://stackoverflow.com/questions/79968/split-a-string-by-spaces-preserving-quoted-substrings-in-python/524796#524796
#    http://stackoverflow.com/questions/6706953/python-using-subprocess-to-call-sed#6707003
#    http://stackoverflow.com/questions/6584871/remove-last-character-if-its-a-backslash/6584893#6584893
#    http://stackoverflow.com/questions/2212643/python-recursive-folder-read/2212728#2212728
#    parallel lists: http://stackoverflow.com/questions/1663807/how-can-i-iterate-through-two-lists-in-parallel-in-python
#    file renames http://stackoverflow.com/questions/225735/batch-renaming-of-files-in-a-directory/7917798#7917798
# Improve:
#    Add option to specify scrub file
#    Add exclude option to scrub file, such as .git and so on
#    Accept CLI options like source, destination, even exclusions?
#    Add flag for performing file renames as well, or file renames only
import re, shlex, os, sys, shutil
from pathlib import Path

# scrubpy version
scrubpyversion = "2016-10-20a"

# Define functions

def removeComments(string):
   #string = re.sub(re.compile("/\*.*?\*/",re.DOTALL ) ,"", string)
   #string = re.sub(re.compile("//.*?\n" ) ,"" ,string)
   pattern = r"(\".*?\"|\'.*?\')|(/\*.*?\*/|(//|#)[^\r\n]*$)"
   regex = re.compile(pattern, re.MULTILINE|re.DOTALL)
   def _replacer(match):
      if match.group(2) is not None:
         return ""
      else:
         return match.group(1)
   return regex.sub(_replacer, string)

# Main code
stringfile = open('scrub.txt','r')
count=0
thisdir=""
newdir=""
oldstrings=[]
newstrings=[]

while True:
   x = stringfile.readline().rstrip()
   count += 1
   if not x: break
   x = removeComments(x)
   #print("x=" + x)
   y = shlex.split (x)
   if len(y) >= 1:
      if thisdir == "":
         thisdir = y[0]
      elif newdir == "":
         newdir = y[0]
   if len(y) >= 2: 
      #print("y[0]=" + y[0] + "\t and y[1]=" + y[1])
      oldstrings.append(y[0])
      newstrings.append(y[1])

# After the file is done
stringfile.close()
#newdir = thisdir.rstrip('\/') + ".scrubbed/"

if False:
   print("\nthisdir=" + thisdir)
   print("newdir=" + newdir + '\n')
   print("oldstrings are:")
   print(oldstrings)
   print("newstrings are:")
   print(newstrings)

# Clean scrubbed directory
try:
   shutil.rmtree(newdir)
except:
   foo=1

shutil.copytree(thisdir,newdir,symlinks=True)

# Execute substitutions
for rootfolder, subdirs, files in os.walk(thisdir):
   for filename in files:
      sourcepath = os.path.join(rootfolder, filename)
      with open( sourcepath, "r" ) as source:
         if not ".swp" in source.name and not ".git" in source.name and not ".tgz" in source.name:
            destdir = rootfolder.replace(thisdir.rstrip('\/'),newdir.rstrip('\/'))
            destfile = os.path.join(destdir, filename)
            #print("sourcefile=" + source.name)
            #print("destfile=" + destfile + '\n')
            with open( destfile, "w") as target:
               data = source.read()
               for oldword, newword in zip(oldstrings, newstrings):
                  data = data.replace(oldword,newword)
               changed = data
               target.write(changed)

# Execute file renames
# Used "file renames" reference, as well as the structure of directory traversal used earlier, which was from a different source.
for rootfolder, subdirs, files in os.walk(newdir):
   for filename in files:
      oldpath = os.path.join(rootfolder, filename)
      for oldword, newword in zip(oldstrings, newstrings):
         if oldword in oldpath:
            #print("oldword=" + oldword + "\toldpath=" + oldpath)
            os.rename(oldpath, oldpath.replace(oldword,newword))
