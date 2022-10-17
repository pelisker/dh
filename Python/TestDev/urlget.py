#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import json
#import pyperclip
import requests


if len(sys.argv) == 2:
    param_url = sys.argv[1]
#    param_url='http://b24.deephouse.pro/rest/15/z6e11hlu8ymigstb/crm.livefeedmessage.add?fields%5BPOST_TITLE%5D=[Доставка]&fields%5BMESSAGE%5D=ТЕСТОВЫЙ КОММЕНТАРИЙ&fields%5BENTITYTYPEID%5D=2&fields%5BENTITYID%5D=158666'
#    if param_json[0] in ('"', "'"):
        #pyperclip.copy('В буфере обмена должен содержаться словарь jsonData без внешних ковычек')
#        exit(1)

    # headers = {
    #     'Content-Type': 'application/json',
    #     'charset': 'UTF-8'
    # }

#    data = json.dumps(param_json)
 #   data = json.loads(data)

#    try:
    resp = requests.get(url=param_url)
                        #, headers=headders, auth=(param_key1, param_key2), data=data.encode('utf-8')

    if resp.status_code == 200:
        res = json.loads(resp.text)
        #pyperclip.copy(res['Model']['Url'])
        print(res)
        exit(0)
    else:
        print(resp.raise_for_status())
#        pyperclip.copy(resp.status_code, resp.raise_for_status())
#    except requests.exceptions.RequestException as err:
#        pyperclip.copy(err)

#        exit(1)
else:
    print("Ошибка. Не передан url.")
#     exit(1)

