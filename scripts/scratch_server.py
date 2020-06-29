#!/usr/bin/python
"""1 hour temporary server for testing"""

import requests
import sys, json, time, os, signal

def main():
    headers = {'API-Key': 'FSP2CK3X3JK4AW3MZNJ2TK57AV72NA3DDUDQ'}

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
    r = requests.post("""https://api.vultr.com/v1/server/create 
        --data 'DCID=6' 
        --data 'VPSPLANID=201' 
        --data 'hostname=scratch' 
        --data 'notify_activate=yes' 
        --data 'SCRIPTID=720113' 
        --data 'OSID=352'""", headers=headers)
    print(r.text)

    print("SCRIPTS")
    r = requests.get('https://api.vultr.com/v1/startupscript/list', headers=headers)
    print(json.dumps(json.loads(r.text), indent=4, sort_keys=True))

    print("SERVER LIST")
    r = requests.get('https://api.vultr.com/v1/server/list', headers=headers)
    #print(r.text)
    json_data = json.loads(r.text)
    #print(r.json())
    print(json.dumps(json_data, indent=4, sort_keys=True))
    #print(json_data['ram'])
    #time.sleep(100)
    #print(json_data.get('location'))

main()