#! /usr/bin/env python

# Written by Kjetil Matheussen: k.s.matheussen@notam02.no


import sys

python_version = sys.version_info[0]

if python_version==3:
    import urllib.request, urllib.error, urllib.parse
else:
    import urllib2

import readline

headers = {"Content-type": "text/plain", "Accept": "text/plain"}

def post2(url, data):
    request = urllib2.Request(url, data, headers)
    try:
        response = urllib2.urlopen(request)
    except urllib2.URLError:
        print("<Unable to contact Radium>")
        return

    all_data = ""

    data = response.read(1)
    while data:
        all_data = all_data + data
        sys.stdout.write( '%s' % data )
        sys.stdout.flush()
        data = response.read(1)
    response.close()

    return all_data


def post3(url, data):
    request = urllib.request.Request(url, data.encode(), headers)
    
    try:
        response = urllib.request.urlopen(request)
    except urllib.error.URLError:
        print("<Unable to contact Radium>")
        return

    all_data = ""

    data = response.read(1)
    while data:
        str_data = str(data, encoding="utf-8")
        all_data = all_data + str_data
        sys.stdout.write( '%s' % str_data)
        sys.stdout.flush()
        data = response.read(1)
    response.close()

    return all_data


def post(url, data):
    if python_version==3:
        return post3(url, data)
    else:
        return post2(url, data)
    
    
def get_input(prompt):
    try:
        if python_version==3:
            return input(prompt)
        else:
            return raw_input(prompt)
    except EOFError:
        sys.exit(0)


def start(prompt, url):
    line = get_input(prompt)
    while True:
        result = post(url, line)
        if result=="":
            line = get_input("")
        else:
            print("\n")
            line = get_input(prompt)


if __name__ == "__main__":

    prompt = "s7> "
    url = "http://localhost:6080"

    if len(sys.argv)>1:
        if (sys.argv[1].startswith("-")):
            print("Usage: s7repl <prompt> <url>")
            print("       Default value for <prompt> is \"s7> \"")
            print("       Default value for <url> is http://localhost:6080")
            sys.exit(0)
        prompt = sys.argv[1]

    if len(sys.argv)>2:
        url = sys.argv[2]

    start(prompt, url)
