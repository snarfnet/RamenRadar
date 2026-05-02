# -*- coding: utf-8 -*-
import jwt, time, requests, json, sys, os

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
p8 = open('/tmp/asc_key.p8').read()
BUNDLE_ID = 'com.tokyonasu.RamenRadar'

def make_token():
    return jwt.encode({'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'}, p8, algorithm='ES256', headers={'kid': KEY_ID})

def api(method, path, payload=None):
    h = {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json; charset=utf-8'}
    kw = {}
    if payload:
        kw['data'] = json.dumps(payload, ensure_ascii=False).encode('utf-8')
    return requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}', headers=h, **kw)

# Get app ID
r = api('GET', f'/apps?filter[bundleId]={BUNDLE_ID}')
apps = r.json().get('data', [])
if not apps:
    print(f'App {BUNDLE_ID} not found in ASC. Register it first.')
    sys.exit(0)

APP_ID = apps[0]['id']
print(f'App ID: {APP_ID}')

# Get version
r = api('GET', f'/apps/{APP_ID}/appStoreVersions?filter[platform]=IOS&limit=1')
versions = r.json().get('data', [])
if not versions:
    print('No version found')
    sys.exit(0)

VERSION_ID = versions[0]['id']
state = versions[0]['attributes']['appStoreState']
print(f'Version: {VERSION_ID} state={state}')

if state == 'READY_FOR_SALE':
    print('Already on sale, skip')
    sys.exit(0)

# Wait for build processing
build_num = sys.argv[1] if len(sys.argv) > 1 else None
if build_num:
    print(f'Waiting for build {build_num} to process...')
    for i in range(30):
        r = api('GET', f'/builds?filter[app]={APP_ID}&filter[version]={build_num}&filter[processingState]=VALID')
        builds = r.json().get('data', [])
        if builds:
            build_id = builds[0]['id']
            print(f'Build {build_num} is VALID: {build_id}')
            # Attach build to version
            r2 = api('PATCH', f'/appStoreVersions/{VERSION_ID}', {
                'data': {
                    'type': 'appStoreVersions', 'id': VERSION_ID,
                    'relationships': {
                        'build': {'data': {'type': 'builds', 'id': build_id}}
                    }
                }
            })
            print(f'Attach build: {r2.status_code}')
            break
        time.sleep(30)
    else:
        print('Build not ready after 15 min, skipping submit')
        sys.exit(0)

print('Done - submit manually after metadata setup')
