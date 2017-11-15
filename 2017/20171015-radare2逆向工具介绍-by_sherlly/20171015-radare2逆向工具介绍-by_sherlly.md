#Radare 2---逆向工程和二进制分析框架


##简介
radare2是一个开源的逆向工程和二进制分析框架，包括反汇编、分析数据、打补丁、比较数据、搜索、替换、虚拟化等等，同时具备超强的脚本加载能力，它可以运行在几乎所有主流的平台（GNU/Linux, .Windows *BSD, iOS, OSX, Solaris…）并且支持很多的cpu架构以及文件格式。

##安装
	
	git clone https://github.com/radare/radare2.git
	cd radare2
	./sys/install.sh

##获取二进制文件信息

使用框架中的**rabin2**工具，可以获取包括ELF, PE, Mach-O, Java CLASS文件的区段、头信息、导入导出表、字符串相关、入口点等等，并且支持几种格式的输出文件.

通过 -I 参数 来让 rabin2 打印出二进制文件的系统属性、语言、字节序、框架、以及使用了哪些加固技术（canary, pic, nx）

	>rabin2 -I crackme

	arch     x86
	binsz    6220
	bintype  elf
	bits     32
	canary   false
	class    ELF32
	crypto   false
	endian   little
	havecode true
	intrp    /lib/ld-linux.so.2
	lang     c
	linenum  true
	lsyms    true
	machine  Intel 80386
	maxopsz  16
	minopsz  1
	nx       false
	os       linux
	pcalign  0
	pic      false
	relocs   true
	relro    partial
	rpath    NONE
	static   false
	stripped false
	subsys   linux

##常用命令

	i -h  //用于查看文件信息
	ia  //显示程序所有信息（包括节表，区段，入口信息，导入表，导出表...）
	ie //查看程序入口点
	iz //查看程序数据段中所有可见字符串
	izz //查看程序所有可见字符串
	il //查看链接的库
	aa  //用于对文件具体分析
	axt //在 data/code段里找寻某个地址相关的引用
	afl //分析函数列表（Analyze Functions List）
	s //打印当前地址
	s addr //跳转到该地址
	pdf //输出反汇编代码
	ahi s @@=addr1 addr2 ... //设置字符串特定的偏移地址
	! [shell] //执行系统命令
	ood [str] //添加命令行参数
	dc //执行程序

##分析

	r2 -A ./crackme //载入时自动分析
分析完成之后， r2会将所有有用的信息和特定的名字绑定在一起，比如区段、函数、符号、字符串，这些都被称作 'flags', flags 被整合进\<flag spaces>，一个 flag 是所有类似特征的集合.

使用**fs**命令展示所有的flag。
	
	fs <flag spaces>;f  //打印该集合具体信息
	[0x08048370]> fs imports;f
	0x08048320 6 sym.imp.strcmp
	0x08048330 6 sym.imp.strcpy
	0x08048340 6 sym.imp.puts
	0x00000000 16 loc.imp.__gmon_start__
	0x08048350 6 sym.imp.__libc_start_main

##字符串

	iz //搜索字符串
	axt @@ str.* //列出字符串标志，同时也包括函数名，找到它们所处位置以及何处被调用
	//@@ 用来在地址空间里不断地匹配后面一系列相关的命令


##视图模式

按V开启，p/P可以在不同的模式之间切换，x/X可以列出当前函数的引用状况

使用 k 和 j 来上下移动，按回车键将在 call 和 jmp 的时候跳转到目的地址，同时上图里有一些方括号里面有数字，在键盘上按相应的数字就会跳转到对应的函数和地址处。


##反汇编某个具体函数

	pdf @sym.beet  //通过afl命令可知函数名称	
	? 0x88 //计算
	ahi s @@=0x080485a3 0x080485ad 0x080485b7
	//Megabeets
	rahash2：包含多种算法，用于求一个文件或者字符串的校验值
	//!rahash2 -E rot -S s:13 -s 'Megabeets\n'