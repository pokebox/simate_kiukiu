#!/usr/bin/env perl
use Mojo::Webqq;
my ($host,$port,$post_api);

$host = "0.0.0.0";	#发送消息接口监听地址，没有特殊需要请不要修改
$port = 15105;		#发送消息接口监听端口，修改为自己希望监听的端口
#$post_api = 'http://xxxx';  #接收到的消息上报接口，如果不需要接收消息上报，可以删除或注释此行


my $client = Mojo::Webqq->new(tmpdir=>"/var/tmp");	##创建登录，所有缓存保存在/var/tmp里

$client->load("ShowMsg");	##显示数据在屏幕上
$client->load("ProgramCode");	##程序代码执行
$client->load("Translation");	##多国语翻译
$client->load("Openqq",data=>{
	listen	=> [ {host=>$host,port=>$port} ],
	auth	=> sub {my($param,$controller) = @_},	##返回数据避免curl卡死
	post_api => $post_api
});

$client->on(receive_message=>sub{	##收到消息事件
	my ($client,$msg) = @_;		##接收到的消息事件变量传递
	$msg->dump;
	if($msg->type eq 'message')	##如果消息类型是好友
	{
		if($msg->content eq 'update')
		{
			$client->update_friend();
			$client->update_group();
			$client->update_discuss();
		}
		my $strs = "#T#bash";
		if($msg->content =~ /$strs/)
		{
			print("阻塞输出\n");
			#$client->send_message($msg->sender->id,"ok");
			system("/mnt/test.sh",$msg->type,$msg->sender->qq,$msg->sender->displayname,$msg->content);
				##脚本	消息类型	对方帐号	昵称	内容
			#print ("===========",$bakstr,"===……===");
			#$client->reply_message($msg,$bakstr);
	}
		else
		{
			print("非阻塞输出\n");
			$client->spawn(
				cmd		=> ['/mnt/test.sh',$msg->type,$msg->sender->qq,$msg->sender->displayname,$msg->content],
				exec_timeout	=> 240,
				stdout_cb	=> sub{
					my($pid,$chunk) = @_;
					$client->print("非阻塞输出：",$chunk,"\n");
				},
				exit_cb		=> sub{
					my($pid,$res) = @_;
					$client->reply_message($msg,$res->{stdout});
					#$client->reply_message($msg,$res->{stderr});
					$client->print("标准错误：",$res->{stderr},"\n");
				}
			);
		}
	}
	elsif($msg->type eq 'group_message')
	{
		my $strs = "#T#bash";
		if($msg->content =~ /$strs/){
			print("阻塞输出\n");
			system("/mnt/test.sh",$msg->type,$msg->sender->gnumber,$msg->sender->gname,$msg->sender->qq,$msg->content);	##执行bash代码
			##	脚本地址	消息类型	消息来源群号	群昵称		群组对方QQ号		消息内容
		}
		else{
			print("非阻塞输出\n");
			$client->spawn(
				cmd		=> ['/mnt/test.sh',$msg->type,$msg->sender->gnumber,$msg->sender->gname,$msg->content,$msg->sender->qq],
				exec_timeout	=> 30,
				stdout_cb	=> sub{
					my($pid,$chunk) = @_;
				#	$client->reply_message($msg,$res->{stdout});
				#	$client->reply_message($msg,$res->{stderr});

					$client->print("非阻塞输出：",$chunk,"\n");
				},
				exit_cb		=> sub{
					my($pid,$res) = @_;
					$client->reply_message($msg,$res->{stdout});
					#$client->reply_message($msg,$res->{stderr});
					$client->print("标准错误：",$res->{stderr},"\n");
				}
			);
		}
	}
});

$client->run();	##运行实例
