#! /usr/local/bin/python

import sys
import re

#####################################################
title_in_group={}
title_in_ali={}

#####################################################
def get_title_in_ali_file(ali_file):
    ali_file_handle=open(ali_file,'r')
    for line in ali_file_handle:
        line=line.rstrip()
        m=re.search(r'^>(.+)',line)
        if m:
            title_in_ali[m.group(1)]=1

def check_group_title(group_file):
    group_file_handle=open(group_file,'r')
    lineno=0
    for line in group_file_handle:
        line=line.rstrip()
	lineno+=1
        group_k=0
        for i in line.split("\t"):
            if i in title_in_ali.keys():
	        group_k+=1
		continue
        if group_k == 0:
            group_file_handle.close()
            return(lineno)
    group_file_handle.close()
    return('OK')

ali_file=sys.argv[1]
group_file=sys.argv[2]

##############################################
get_title_in_ali_file(ali_file)
return_check_group_title = check_group_title(group_file)

print "OK" if return_check_group_title == 'OK' else return_check_group_title ,

