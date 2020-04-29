#!/usr/bin/python
"""1 hour temporary server for testing"""

import requests
import sys, json, time, os, signal

def main():
    headers = {'API-Key': 'COY7KIJQQ7SV33X6DEUR3BEA7MGCMVLHCLJA'}

    # If arg exists, kill existing script PID to keep server indefinitely.
    if len(sys.argv) > 1:
        try:
            f = open('/tmp/scratch_server.pid', 'r')
            os.remove('/tmp/scratch_server.pid')
            os.kill(int(f.read()), signal.SIGTERM)
            f.close()
        except FileNotFoundError:
            print('/tmp/scratch_server.pid not found, perhaps server already deleted?')
        except ProcessLookupError:
            print('Previous script PID not found, perhaps server already deleted?')
        except Exception as err:
            print('Unhandled exception has occurred: ' + str(err))
        finally:
            exit(0)

    # Create PID file
    f = open('/tmp/scratch_server.pid', 'w')
    f.write(str(os.getpid()))
    f.close()

    # Create server
    requests.get("""https://api.vultr.com/v1/server/create 
        --data 'DCID=6' 
        --data 'VPSPLANID=201' 
        --data 'hostname=scratch' 
        --data 'notify_activate=yes' 
        --data 'SCRIPTID=' 
        --data 'OSID=352'""", headers=headers)

    r = requests.get('https://api.vultr.com/v1/startupscript/list', headers=headers)

    r = requests.get('https://api.vultr.com/v1/server/list', headers=headers)
    print(r.text)
    json_data = json.loads(r.text)
    print(r.json())
    print(json_data)
    print(json_data['ram'])
    #time.sleep(100)
    #print(json_data.get('location'))

main()