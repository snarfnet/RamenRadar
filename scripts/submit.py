# -*- coding: utf-8 -*-
import json
import os
import re
import sys
import time

import jwt
import requests

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
BUNDLE_ID = 'com.tokyonasu.RamenRadar'

p8_path = os.path.expanduser('~/.appstoreconnect/private_keys/AuthKey_WDXGY9WX55.p8')
p8 = open(p8_path).read()


def project_version():
    try:
        text = open('project.yml', encoding='utf-8').read()
        match = re.search(r'MARKETING_VERSION:\s*([0-9.]+)', text)
        if match:
            return match.group(1)
    except OSError:
        pass
    return '1.1'


APP_VERSION = os.environ.get('APP_VERSION', project_version())
BUILD_NUMBER = sys.argv[1] if len(sys.argv) > 1 else None
PREPARE_ONLY = '--prepare-only' in sys.argv


def make_token():
    return jwt.encode(
        {'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'},
        p8,
        algorithm='ES256',
        headers={'kid': KEY_ID},
    )


def api(method, path, payload=None):
    headers = {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json; charset=utf-8'}
    kwargs = {}
    if payload is not None:
        kwargs['data'] = json.dumps(payload, ensure_ascii=False).encode('utf-8')
    return requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}', headers=headers, **kwargs)


def fail(message, response=None):
    print(message)
    if response is not None:
        print(response.text[:500])
    sys.exit(1)


def app_id():
    response = api('GET', f'/apps?filter[bundleId]={BUNDLE_ID}')
    apps = response.json().get('data', [])
    if not apps:
        fail(f'App {BUNDLE_ID} not found in ASC.')
    return apps[0]['id']


def list_versions(app):
    response = api('GET', f'/apps/{app}/appStoreVersions?filter[platform]=IOS&limit=10')
    return response.json().get('data', [])


def create_version(app):
    print(f'Creating App Store version {APP_VERSION}...')
    response = api('POST', '/appStoreVersions', {
        'data': {
            'type': 'appStoreVersions',
            'attributes': {'platform': 'IOS', 'versionString': APP_VERSION},
            'relationships': {'app': {'data': {'type': 'apps', 'id': app}}},
        }
    })
    if response.status_code not in (200, 201):
        fail('Failed to create App Store version.', response)
    return response.json()['data']


def get_or_create_version(app):
    versions = list_versions(app)
    editable_states = {
        'PREPARE_FOR_SUBMISSION',
        'DEVELOPER_REJECTED',
        'REJECTED',
        'METADATA_REJECTED',
        'WAITING_FOR_REVIEW',
        'IN_REVIEW',
    }

    for version in versions:
        attrs = version['attributes']
        if attrs.get('versionString') == APP_VERSION and attrs.get('appStoreState') in editable_states:
            print(f'Found version {APP_VERSION}: {version["id"]} state={attrs["appStoreState"]}')
            return version

    return create_version(app)


def wait_for_build(app):
    if not BUILD_NUMBER:
        fail('Build number is required.')

    print(f'Waiting for build {BUILD_NUMBER} to process...')
    for attempt in range(80):
        response = api('GET', f'/builds?filter[app]={app}&filter[version]={BUILD_NUMBER}&filter[processingState]=VALID&limit=1')
        builds = response.json().get('data', [])
        if builds:
            build = builds[0]
            print(f'Build {BUILD_NUMBER} is VALID: {build["id"]}')
            return build
        print(f'  Waiting... ({attempt + 1}/80)')
        time.sleep(30)
    fail('Build not ready after 40 minutes.')


def set_export_compliance(build):
    response = api('PATCH', f'/builds/{build["id"]}', {
        'data': {
            'type': 'builds',
            'id': build['id'],
            'attributes': {'usesNonExemptEncryption': False},
        }
    })
    print(f'Export compliance: {response.status_code}')


def attach_build(version, build):
    response = api('PATCH', f'/appStoreVersions/{version["id"]}/relationships/build', {
        'data': {'type': 'builds', 'id': build['id']}
    })
    print(f'Build assigned: {response.status_code}')
    if response.status_code not in (200, 204):
        fail('Failed to assign build.', response)


def cancel_blocking_submissions(app):
    for state in ['UNRESOLVED_ISSUES', 'READY_FOR_REVIEW']:
        response = api('GET', f'/apps/{app}/reviewSubmissions?filter[state]={state}')
        if response.status_code != 200:
            continue
        for submission in response.json().get('data', []):
            sid = submission['id']
            cancel = api('PATCH', f'/reviewSubmissions/{sid}', {
                'data': {'type': 'reviewSubmissions', 'id': sid, 'attributes': {'canceled': True}}
            })
            print(f'Cancel submission {sid} state={state}: {cancel.status_code}')


def submit_for_review(app, version):
    state = version['attributes']['appStoreState']
    if state in ('WAITING_FOR_REVIEW', 'IN_REVIEW'):
        print(f'Already submitted: {state}')
        return

    cancel_blocking_submissions(app)

    submission_id = None
    for attempt in range(5):
        response = api('POST', '/reviewSubmissions', {
            'data': {
                'type': 'reviewSubmissions',
                'relationships': {'app': {'data': {'type': 'apps', 'id': app}}},
            }
        })
        if response.status_code == 201:
            submission_id = response.json()['data']['id']
            print(f'ReviewSubmission created: {submission_id}')
            break
        print(f'Create reviewSubmission attempt {attempt + 1}/5 failed: {response.status_code} {response.text[:200]}')
        time.sleep(15)

    if not submission_id:
        fail('Could not create review submission.')

    item_added = False
    for attempt in range(5):
        response = api('POST', '/reviewSubmissionItems', {
            'data': {
                'type': 'reviewSubmissionItems',
                'relationships': {
                    'reviewSubmission': {'data': {'type': 'reviewSubmissions', 'id': submission_id}},
                    'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': version['id']}},
                },
            }
        })
        print(f'Add item attempt {attempt + 1}/5: {response.status_code}')
        if response.status_code == 201:
            item_added = True
            break
        time.sleep(15)

    if not item_added:
        fail('Failed to add review item.', response)

    response = api('PATCH', f'/reviewSubmissions/{submission_id}', {
        'data': {
            'type': 'reviewSubmissions',
            'id': submission_id,
            'attributes': {'submitted': True},
        }
    })
    if response.status_code == 200:
        print(f'Submitted! State: {response.json()["data"]["attributes"]["state"]}')
    else:
        fail('Submit failed.', response)


app = app_id()
print(f'App ID: {app}')
print(f'App Store version: {APP_VERSION}')
version = get_or_create_version(app)

if PREPARE_ONLY:
    print(f'Prepared version: {version["id"]} state={version["attributes"]["appStoreState"]}')
    sys.exit(0)

build = wait_for_build(app)
set_export_compliance(build)
attach_build(version, build)
submit_for_review(app, version)
