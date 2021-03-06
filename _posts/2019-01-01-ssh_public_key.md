---
layout: post
title: 洗澡时，我终于跑出来喊出了我的Eureka
description: 今天与一位帅气的同事一起解决了一下 ssh 的相关问题，在我装逼的提及不需要显式指定 `identity key` 的时候，顺道提及 `known_hosts` 也是一样的时候，说到了`known_hosts`的现象..
categories:
- 技术
tags:
- go
---

## 洗澡时，我终于跑出来喊出了我的Eureka

今天与一位帅气的同事一起解决了一下 ssh 的相关问题，在我装逼的提及不需要显式指定 `identity key` 的时候，顺道提及 `known_hosts` 也是一样的时候，说到了`known_hosts`的现象：

- 第一次 ssh 到一台服务器，需要用输入 yes 来确认此服务器；

-  当一个已经连接过的域名换服务器时，会禁止连接，警告有可能有中间人，需要手动删除` known_host` 里的此记录；



  但是原理被含糊不清的略过去了———至少没有刻意提到，因为我是不大懂的。


在今晚洗澡时，回想了一下今天的事情，想到了这件事情，不禁尝试想清楚 `kown_host` 是啥东西，为什么需要它。

前几天看到知乎上，有一篇文章介绍了拉马努金自己尝试推导一切未知但已成结论的数学公式，作者学习此方法自己尝试推导出机器学习的论文。

不知道是不是潜意识的影响（我在那时肯定没想到这篇文章），我在结合以上已知 `known_host` 的两点现象，以及以前零散的 ssh 原理知识，尝试推导 ssh 为什么运作的。



RSA 的原理无需累述，就用我以前总结过的为介绍吧：

> RSA 是非对称加密算法, 对称算法就是双方用同一个密钥加密。 RSA 是基于对两个质数相乘容易，而将其合数 分解很难的这个特点进行的加密算法 生成公钥与私钥, 公钥加密而私钥解密, 或者相反都可以。 一般公钥公开到网上, 想发送信息给你的人用公钥加密, 而只有你拥有私钥可以解密, 这样确保了信息的保密。 或者你用私钥加密, 其他所有人都可以用公钥解密你的信息, 这样可以确保信息是由你所发出。 网上发邮件或者个人网站上所用到的签名, 就是使用此技术。

 而 SSH 就是利用了这个原理，你可以从此方面尝试去推导出你如何做一个 ssh。



而我推导出的过程是这样的：

**目的就是 server 要识别 client 就是 `authorize_keys` 里记录的 client**

1. 在 server上的`authorize_keys`里添加 client 的公钥了(这步大家都知道)

1. client发起ssh连接到 server，发送公钥给 server

1. server 用client 发送的公钥对比 `authorize_keys`里的记录是否一致，认证 client 是否有权限
2. 此时 server 发送一个字符串（如"generated by server"）发送给 client，目的就是 client 用私钥加密后，发回去后，server 可以解密，与记录的字符串对比一致
3. 此时可以确认 client 就是`authorize_keys` 里记录的 client了

以上一切完成。

为什么需要`known_host`呢？ 上述过程有一个问题就是，无法抵御中间人攻击。

假如在你以后链接 server 时，被中间人攻击了，中间人模仿 server 的行为与你进行 ssh 校验，你就会连上去，并且难以发现。

因此显然易见的一个方法就是，在第一次建立连接成功后，在一个文件里记录 `IP，公钥`这样的键值对，以后连接时对比一下与第一次连接的公钥是否一致即可。 而这个文件就被 ssh 命名为 `known_hosts` ，因此不一致时，拒绝了你的 ssh 连接，并且提示 中间人攻击。

那么保证第一次连接是对的话，就只有人工去对比了。 服务器自己公开公钥信息了，客户端自己去对比。



------

#### 对比结果

事后对比，以上的做法是对的，只是没那么严谨。

有以下几个细节是不同的：

1. 客户端应该是需要发送公钥到服务器的，目前没有看到有说明这个的地方，需要再查
2. 发送的固定字符串，不是用明文，而是用客户端的公钥加密了
3. 服务器发给客户端去做私钥加密时，生成的不是固定的字符串，而是随机字符串（这个是细节没有打磨，因为发送固定字符串，明显客户端私钥加密过的东西是固定的，就无法保密了）
4. 最后对比这个随机字符串时，还用了`SessionKey`来做 md5，还没细查



------

#### 感想

以上的文章，技术细节不怎么重要，重要的是背后的一些大家都知道道理：

对一切保持好奇心，尽量探寻其中的原理，这才对得住`计算机科学`。赫歇尔对好奇七色光实验为何会有额外的温度变化才发现不可见光（红外线，紫外线呢），法拉第不懈尝试各种材料才发现玻璃能帮助磁场让光改变路径，证实磁场与光有关联。  计算机也是基于黑盒上完整的生态圈，如 HTTP，TCP，CPU，PL 等，同样可以对他们保持好奇心，与用拉马努金来推导构建此黑盒，与自己的对比，想必大有裨益。



#### 花絮

Why **Eurekai** ?
Eureka – （希腊语：εὕρηκα；拉丁化：Eureka；词义：“我发现了!”）

> 阿基米德在洗澡时发现浮力原理，高兴得来不及穿上裤子，跑到街上大喊：“**Eureka**！”

古希腊学者阿基米德 (Archimedes)，有一天，他在洗澡的时候发现，当他坐进浴盆里时有许多水溢出来，这使得他想到：溢出来的水的体积正好应该等于他身体的体积，这意味着，不规则物体的体积可以精确的被计算，这为他解决了一个棘手的问题。阿基米德想到这里，不禁高兴的从浴盆跳了出来，光着身体在城里边跑边喊叫着 “尤里卡！尤里卡！”，试图与城里的民众分享他的喜悦。

So..
Eureka! Eureka!



在自己设计想清楚了 SSH之后，我在寒冬不禁高兴的从浴室跳了出来，光着身体在客厅边跑边喊叫着 “Molly，Molly”， 跟女票论述了我此番的感想。

因为她对ssh 原理心中一直有根刺，也很感兴趣，让我把 ssh 以及 RSA 的原理都给她说了一遍，草稿如下：



------



3，5，7，11，13，17。。。



191        (13,17)

公钥 《=》私钥



- 公钥加密的东西，可以用私钥来解 =》 别人用我的公钥加密的东西，我有私钥，只有我才能解密，知道这是什么
- 私钥加密的东西，同样可以用公钥来解 => 我加密的东西，别人可以用我公开的私钥来解密 =》 这些东西就是你加密的（这就是你的东西）



公钥暴露，别人无法暴力破解对比出私钥



=》私钥永远不能暴露，不能发送出去，只能放自己机器。



公钥 私钥



公钥放 GitHub服务器

molly ssh到GitHub =》 molly发起ssh链接 -》 发公钥给GitHub -》GitHub就可以跟你放GitHub服务器的公钥做对比，校验你有没有权限 -》“随机生成的字符串” 发给molly -》 molly用私钥来加密随机生成的字符串 ，发给GitHub -》GitHub用molly的公钥来解开这个内容，对比是否刚刚发给molly的随机字符串 =》一切都通了。	



中间人 =》 你要想像中间随便有一个人可以监听你的网络

 molly -- chalres            -- github

1. SSL
2. ~/.ssh/known_hosts 
