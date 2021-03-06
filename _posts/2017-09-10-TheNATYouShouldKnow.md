---
layout: post
title: 内网是你的谎言
description: 关于NAT你所不知道的一切, 作为程序员，我们都知道，ipv4地址很早就不够用了，然后有一项技术，可以内网用同一个外网 ip——是的，那就是 NAT（Network Address Translation），网络地址交换技术。
categories:
- 技术
tags:
- NAT
---

## 关于 NAT，你所不知道的一切
作为程序员，我们都知道，ipv4地址很早就不够用了，然后有一项技术，可以内网用同一个外网 ip——是的，那就是 NAT（Network Address Translation），网络地址交换技术。

它的原理，其实很简单。假如分配给你的内网地址是10.9.8.11， 而公网是169.5.6.1， 内网地址是没办法与外网通信的——因为其他地方也有内网，也会有跟你一样的地址10.9.8.11。

当你要建立一条 tcp 连接（即是访问外部网络时），该TCP端口号就当是80吧， 会先把网络包发送给路由器（通常路由器内含 NAT 了），NAT 用一个表记录下你的内网地址10.9.8.11，端口号：80，而 NAT 会分配一个随机的端口号给你，如467，再把你的地址转换成公网169.5.6.1：467，与你要访问的目标地址建立起链接。

现在你发出去这条路是通了，别人发过来的包，NAT 怎么判断该发回去哪台内网机器呢？

---

 NAT 会分配你一个端口号（在上面是467），所以当有外部网络访问467时，NAT 会根据记录下的表，找到467端口对应的是内网10.9.8.11:80，转发回去。

既然是用表记录了，自然要考虑到表会不会满的问题。端口数量是有限的0~65535，作为程序员的我们都会想到，肯定是要删除很久不用的链接的。是的，一旦NAT 表里某记录很久不活跃，没有包发出收入（通常是5-30分钟，可以自行设置），就会把该记录删除掉。

但是这就带来了一个问题，假如我的程序像 QQ一样，需要长时间的链接呢？ NAT 丢弃不活跃链接的时候，是不会通知内网的你以及外网的程序的，也就是说，是不可能重建的了。

最合理的方法当然就是自己实现心跳包，每隔一段时间程序发送一个小包给对方，对方也发回来，不仅保活，也可以检查服务是否遇到不可知错误而中断了。 不一定需要自己实现心跳包，对稳定性需求不高，可以用 linux 内核提供的 TCP keepalive。启用后，系统会按设定的时间（默认是2小时），发送一个包过去。

```
# cat /proc/sys/net/ipv4/tcp_keepalive_time
7200
# cat /proc/sys/net/ipv4/tcp_keepalive_intvl
75
# cat /proc/sys/net/ipv4/tcp_keepalive_probes
9
```

* `tcp_keepalive_time`: 如果在该时间内没有数据往来，则发送探测包。 
* `tcp_keepalive_intvl`: 探测包发送间隔时间。 
* `tcp_keepalive_probes`: 尝试探测的次数。如果发送的探测包次数超过该值仍然没有收到对方响应，则认为连接已失效并关闭连接。


当然默认的2小时比较鸡肋，2小时内没有数据来往，NAT 早踢了你的链接了，一个比较合理的设定是15-30分钟。

---
  

## iptables
Linux 本身就能够做一个 NAT，你知道吗？

想想 docker 是怎么样访问外部网络的？docker 里的 container（容器）都是内网10.xx.xx.xx，宿主机是怎么样与内网通信呢？

Yes，答案一样是 NAT。

Linux 本身就提供了 iptables来做 NAT，具体流程from《鸟哥的 linux 私房菜》：

1. 先经过 NAT table 的 PREROUTING 链；
2. 经由路由判断确定这个封包是要进入本机与否，若不进入本机，则下一步；
3. 再经过 Filter table 的 FORWARD 链；
4. 通过 NAT table 的 POSTROUTING 链，最后传送出去。

PREROUTING会修改目标IP， POSTROUTING链会修改来源 IP， 通常我们的 NAT 内网转外网是修改来源 IP（即内网 IP），成为来源 NAT（Source NAT, SNAT）。
