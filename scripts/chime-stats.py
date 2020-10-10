# {"requirements": ["requests"]} #nix
import datetime
import json
import requests

from os.path import expanduser

with open(expanduser('~/.config/my/secrets/github-api-key')) as f:
    auth = f.read().strip()

stats = json.dumps({
    stat: requests.get(
        'https://api.github.com/repos/jeremyschlatter/chime/traffic/' + stat,
        headers={'authorization': 'token ' + auth},
    ).json()
    for stat in ['popular/referrers', 'popular/paths', 'views', 'clones']
})

path = expanduser(f'~/.local/share/my/chime-traffic/{datetime.datetime.now().strftime("%Y-%m-%d-%H:%M:%S")}.json')

with open(path, 'w') as f:
    f.write(stats)

print(f'\n{path}:\n\n{stats}\n')
