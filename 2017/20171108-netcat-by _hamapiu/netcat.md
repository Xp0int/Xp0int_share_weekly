#netcat-nc
连接和重定向套接字(Concatenate and redirect sockets)

### 0x00 介绍
>Netcat (often abbreviated to nc) is a computer networking utility for reading from and writing to network connections using TCP or UDP. Netcat is designed to be a dependable back-end that can be used directly or easily driven by other programs and scripts. At the same time, it is a feature-rich network debugging and investigation tool, since it can produce almost any kind of connection its user could need and has a number of built-in capabilities.

>Its list of features includes port scanning, transferring files, and port listening, and it can be used as a backdoor.

![这里写图片描述](http://img.blog.csdn.net/20171117191653410?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvUDIwMTcxMTg=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

### 0x01 连接模式/监听模式：
连接模式应该就是不停发送数据，监听模式应该就是不发送数据，还有特殊的其他模式，如HTTP代理服务器模式．
在连接模式下，ncat作为客户端，在监听模式下，ncat作为服务器．


### 0x02 telnet/获取banner
作用：远程服务

命令：nc -vn IP port（可nc -h查看其他选项）

补充：-v 详细输出 -n不进行DNS解析

举例：远程登陆pop3邮箱（注意先获取IP，原因是nc解析域名速度慢），即可远程收发邮件。
![这里写图片描述](http://img.blog.csdn.net/20171109004401422?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvUDIwMTcxMTg=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

### 0x03 传输
作用：传输文本信息、文件、流媒体，加密传输文件，远程克隆硬盘，电子审计

命令：根据管道命令或重定向达到不同作用

服务器端 nc -l -p port

客户端 nc -vn 服务器IP 服务器开放port

补充：-l listen侦听 -p指定端口

举例：查看可疑进程
![这里写图片描述](http://img.blog.csdn.net/20171109010052747?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvUDIwMTcxMTg=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

### 0x04 端口扫描
作用：确定弱点漏洞

命令：nc -nvz IP 端口范围

举例：
![这里写图片描述](http://img.blog.csdn.net/20171117191620226?watermark/2/text/aHR0cDovL2Jsb2cuY3Nkbi5uZXQvUDIwMTcxMTg=/font/5a6L5L2T/fontsize/400/fill/I0JBQkFCMA==/dissolve/70/gravity/SouthEast)

### 0x05 远程控制
命令：

服务器 nc -lp port -c bash

客户端 nc -nv IP port

补充：-c 连接建立后执行shell
