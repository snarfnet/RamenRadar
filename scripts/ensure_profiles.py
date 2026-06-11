# -*- coding: utf-8 -*-
import base64
import os
import time
from pathlib import Path

import jwt
import requests

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
P8_PATH = os.path.expanduser('~/.appstoreconnect/private_keys/AuthKey_WDXGY9WX55.p8')
TEAM_ID = '83VGKGSQUH'

TARGETS = [
    ('MenNavi iOS App Store', 'com.tokyonasu.RamenRadar', 'IOS_APP_STORE'),
    ('MenNavi Watch App Store', 'com.tokyonasu.RamenRadar.watch', 'IOS_APP_STORE'),
]

p8 = open(P8_PATH).read()


def token():
    return jwt.encode(
        {'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        p8,
        algorithm='ES256',
        headers={'kid': KEY_ID},
    )


def api(method, path, payload=None):
    headers = {'Authorization': f'Bearer {token()}', 'Content-Type': 'application/json'}
    kwargs = {}
    if payload is not None:
        kwargs['json'] = payload
    response = requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}', headers=headers, **kwargs)
    return response


def fail(message, response=None):
    print(message)
    if response is not None:
        print(response.status_code, response.text[:800])
    raise SystemExit(1)


def get_bundle_id(identifier):
    response = api('GET', f'/bundleIds?filter[identifier]={identifier}&limit=1')
    data = response.json().get('data', [])
    if data:
        return data[0]['id']

    response = api('POST', '/bundleIds', {
        'data': {
            'type': 'bundleIds',
            'attributes': {
                'identifier': identifier,
                'name': identifier,
                'platform': 'IOS',
            },
        }
    })
    if response.status_code not in (200, 201):
        fail(f'Failed to create bundle ID {identifier}', response)
    return response.json()['data']['id']


def get_certificate_id():
    wanted_serial = os.environ.get('DIST_CERT_SERIAL', '').upper()
    for certificate_type in ('DISTRIBUTION', 'IOS_DISTRIBUTION'):
        response = api('GET', f'/certificates?filter[certificateType]={certificate_type}&limit=20')
        certs = response.json().get('data', [])
        for cert in certs:
            serial = cert.get('attributes', {}).get('serialNumber', '').upper()
            if wanted_serial and serial != wanted_serial:
                continue
            print(f'Using distribution certificate: {cert["id"]} type={certificate_type}')
            return cert['id']
    if wanted_serial:
        fail(f'No App Store Connect distribution certificate matches serial {wanted_serial}.')
    fail('No distribution certificate found.')


def find_profile(name, bundle_id, profile_type, certificate_id):
    response = api('GET', f'/profiles?filter[name]={name}&include=bundleId,certificates&limit=20')
    for profile in response.json().get('data', []):
        attrs = profile.get('attributes', {})
        relationships = profile.get('relationships', {})
        profile_bundle_id = relationships.get('bundleId', {}).get('data', {}).get('id')
        certs = relationships.get('certificates', {}).get('data', [])
        certificate_ids = {cert.get('id') for cert in certs}
        if (
            attrs.get('name') == name
            and attrs.get('profileType') == profile_type
            and profile_bundle_id == bundle_id
            and certificate_id in certificate_ids
        ):
            return profile
    return None


def create_profile(name, bundle_id, profile_type, certificate_id):
    response = api('POST', '/profiles', {
        'data': {
            'type': 'profiles',
            'attributes': {
                'name': name,
                'profileType': profile_type,
            },
            'relationships': {
                'bundleId': {'data': {'type': 'bundleIds', 'id': bundle_id}},
                'certificates': {'data': [{'type': 'certificates', 'id': certificate_id}]},
            },
        }
    })
    if response.status_code not in (200, 201):
        fail(f'Failed to create profile {name}', response)
    return response.json()['data']


def install_profile(profile):
    attrs = profile['attributes']
    content = attrs.get('profileContent')
    uuid = attrs.get('uuid') or profile['id']
    name = attrs.get('name')
    if not content:
        fail(f'Profile {name} has no profileContent.')

    out_dir = Path.home() / 'Library' / 'MobileDevice' / 'Provisioning Profiles'
    out_dir.mkdir(parents=True, exist_ok=True)
    out_path = out_dir / f'{uuid}.mobileprovision'
    out_path.write_bytes(base64.b64decode(content))
    print(f'Installed profile {name}: {out_path}')


certificate_id = get_certificate_id()
for name, identifier, profile_type in TARGETS:
    bundle_id = get_bundle_id(identifier)
    profile = find_profile(name, bundle_id, profile_type, certificate_id)
    if profile:
        print(f'Found profile {name}: {profile["id"]}')
    else:
        profile = create_profile(name, bundle_id, profile_type, certificate_id)
        print(f'Created profile {name}: {profile["id"]}')
    install_profile(profile)
