# -*- coding: utf-8 -*-
import jwt, time, requests, json, sys
sys.stdout.reconfigure(encoding='utf-8')

KEY_ID = 'WDXGY9WX55'
ISSUER = '2be0734f-943a-4d61-9dc9-5d9045c46fec'
p8 = open('C:/Users/Windows/Downloads/AuthKey_WDXGY9WX55.p8').read()
APP_ID = '6765815330'
VERSION_ID = '77672b49-5932-4541-9235-37fb05ca6d2d'

def make_token():
    return jwt.encode({'iss': ISSUER, 'iat': int(time.time()), 'exp': int(time.time()) + 1200, 'aud': 'appstoreconnect-v1'}, p8, algorithm='ES256', headers={'kid': KEY_ID})

def api(method, path, payload=None):
    h = {'Authorization': f'Bearer {make_token()}', 'Content-Type': 'application/json; charset=utf-8'}
    kw = {}
    if payload:
        kw['data'] = json.dumps(payload, ensure_ascii=False).encode('utf-8')
    return requests.request(method, f'https://api.appstoreconnect.apple.com/v1{path}', headers=h, **kw)

SUPPORT_URL = 'https://snarfnet.github.io/RamenRadar/'
MARKETING_URL = 'https://snarfnet.github.io/RamenRadar/'

# === 1. Copyright ===
r = api('PATCH', f'/appStoreVersions/{VERSION_ID}', {
    'data': {'type': 'appStoreVersions', 'id': VERSION_ID, 'attributes': {'copyright': '2026 tokyonasu'}}
})
print(f'Copyright: {r.status_code}')

# === 2. JA localization ===
desc_ja = (
    "近くのうまいラーメン、見つけろ。\n\n"
    "レーダー風UIで周囲のラーメン店をスキャン。人気店・あっさり系・深夜営業を色分け表示。\n\n"
    "【特徴】\n"
    "- レーダースキャンで周囲の店を探索\n"
    "- 混雑ヒートマップで空き状況がわかる\n"
    "- 「今うまい店」を時間帯別に提案\n"
    "- スープ・価格帯・営業時間でフィルター\n"
    "- ワンタップでGoogle Mapsナビ開始\n\n"
    "昼は回転の速い店、深夜は営業中のこってり店を優先表示。"
)
keywords_ja = "ラーメン,麺,検索,近く,レーダー,グルメ,ナビ,混雑,人気,深夜"

r = api('GET', f'/appStoreVersions/{VERSION_ID}/appStoreVersionLocalizations')
locs = r.json()['data']
for loc in locs:
    loc_id = loc['id']
    locale = loc['attributes']['locale']
    r = api('PATCH', f'/appStoreVersionLocalizations/{loc_id}', {
        'data': {'type': 'appStoreVersionLocalizations', 'id': loc_id, 'attributes': {
            'description': desc_ja,
            'keywords': keywords_ja,
            'supportUrl': SUPPORT_URL,
            'marketingUrl': MARKETING_URL,
        }}
    })
    print(f'Update {locale}: {r.status_code}')

# === 3. Create en-US ===
desc_en = (
    "Find the best ramen near you.\n\n"
    "Scan nearby ramen shops with a radar-style UI. Color-coded dots show popular spots, light-flavor shops, and late-night options.\n\n"
    "FEATURES\n"
    "- Radar scan to explore nearby shops\n"
    "- Congestion heatmap shows crowd levels\n"
    "- Time-based hot picks recommendations\n"
    "- Filter by soup type, price, and hours\n"
    "- One-tap Google Maps navigation\n\n"
    "Lunch picks focus on fast service. Late night picks highlight open rich-broth shops."
)
keywords_en = "ramen,noodle,search,nearby,radar,food,navi,crowded,popular,restaurant"

r = api('POST', '/appStoreVersionLocalizations', {
    'data': {
        'type': 'appStoreVersionLocalizations',
        'attributes': {'locale': 'en-US', 'description': desc_en, 'keywords': keywords_en, 'supportUrl': SUPPORT_URL, 'marketingUrl': MARKETING_URL},
        'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': VERSION_ID}}}
    }
})
print(f'Create en-US: {r.status_code}')
if r.status_code not in (200, 201):
    print(r.text[:300])

# === 4. Privacy URL ===
r = api('GET', f'/apps/{APP_ID}/appInfos')
info_id = r.json()['data'][0]['id']
r = api('GET', f'/appInfos/{info_id}/appInfoLocalizations')
for il in r.json()['data']:
    il_id = il['id']
    locale = il['attributes']['locale']
    r2 = api('PATCH', f'/appInfoLocalizations/{il_id}', {
        'data': {'type': 'appInfoLocalizations', 'id': il_id, 'attributes': {'privacyPolicyUrl': 'https://snarfnet.github.io/RamenRadar/privacy'}}
    })
    print(f'Privacy URL ({locale}): {r2.status_code}')

# === 5. Content rights ===
r = api('PATCH', f'/apps/{APP_ID}', {
    'data': {'type': 'apps', 'id': APP_ID, 'attributes': {'contentRightsDeclaration': 'DOES_NOT_USE_THIRD_PARTY_CONTENT'}}
})
print(f'Content rights: {r.status_code}')

# === 6. Pricing (FREE) ===
r = api('GET', f'/apps/{APP_ID}/appPricePoints?filter[territory]=USA&limit=1')
free_pp = r.json()['data'][0]['id']
r = api('POST', '/appPriceSchedules', {
    'data': {
        'type': 'appPriceSchedules',
        'relationships': {
            'app': {'data': {'type': 'apps', 'id': APP_ID}},
            'baseTerritory': {'data': {'type': 'territories', 'id': 'USA'}},
            'manualPrices': {'data': [{'type': 'appPrices', 'id': '${price1}'}]}
        }
    },
    'included': [{'type': 'appPrices', 'id': '${price1}', 'relationships': {'appPricePoint': {'data': {'type': 'appPricePoints', 'id': free_pp}}}}]
})
print(f'Pricing: {r.status_code}')

# === 7. Review detail ===
r = api('POST', '/appStoreReviewDetails', {
    'data': {
        'type': 'appStoreReviewDetails',
        'attributes': {
            'contactFirstName': 'Tokyo', 'contactLastName': 'Nasu',
            'contactEmail': 'tokyonasu@yahoo.co.jp', 'contactPhone': '+81312345678',
            'demoAccountRequired': False,
            'notes': 'No sign-in required. The app shows nearby ramen shops on a radar-style UI. Requires location permission to function.'
        },
        'relationships': {'appStoreVersion': {'data': {'type': 'appStoreVersions', 'id': VERSION_ID}}}
    }
})
print(f'Review detail: {r.status_code}')
if r.status_code not in (200, 201):
    print(r.text[:300])

# === 8. Age rating ===
r = api('GET', f'/appInfos/{info_id}/ageRatingDeclaration')
if r.status_code == 200:
    ard_id = r.json()['data']['id']
    r = api('PATCH', f'/ageRatingDeclarations/{ard_id}', {
        'data': {'type': 'ageRatingDeclarations', 'id': ard_id, 'attributes': {
            'alcoholTobaccoOrDrugUseOrReferences': 'NONE', 'contests': 'NONE',
            'gambling': False, 'gamblingSimulated': 'NONE', 'horrorOrFearThemes': 'NONE',
            'matureOrSuggestiveThemes': 'NONE', 'medicalOrTreatmentInformation': 'NONE',
            'profanityOrCrudeHumor': 'NONE', 'sexualContentGraphicAndNudity': 'NONE',
            'sexualContentOrNudity': 'NONE', 'violenceCartoonOrFantasy': 'NONE',
            'violenceRealistic': 'NONE', 'violenceRealisticProlongedGraphicOrSadistic': 'NONE',
            'unrestrictedWebAccess': False, 'seventeenPlus': False,
            'advertising': True, 'messagingAndChat': False,
            'userGeneratedContent': False, 'lootBox': False,
            'gunsOrOtherWeapons': 'NONE', 'healthOrWellnessTopics': False,
            'parentalControls': False, 'ageAssurance': False,
        }}
    })
    print(f'Age rating: {r.status_code}')

print('\nSetup complete!')
