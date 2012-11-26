<?php
$client= new GearmanClient();
$client->addServer("127.0.0.1");

echo '<meta http-equiv="Content-Type" content="text/html; charset=GB2312" />';

session_start();
if (!isset($_SESSION["user"]) || $_SESSION["user"]=="") {
  if (isset($_POST["name"]))
    login();
  else
    showlogin();
  return;
}

function showlogin($err){
  echo <<<HTML
    <p>$err</p>
    <form method="post">
      用户名：<input name="name" value="" /><br />
      密&nbsp;&nbsp;码：<input name="passwd" type="password" value="" /><br />
      <input type="submit" value="登录"/>
    </form>
HTML;
}

function login(){
  $name=mysql_filter($_POST["name"]);
  $passwd=sha1(mysql_filter($_POST["passwd"]));

  $re1 = sendPOST("chat.53kf.com",'/impl/admin_login_chk.php','name='.urlencode($name).'&passwd='.urlencode($passwd));
  $xml1 = substr($re1, strpos($re1, "<?xml"));
  $xml1 = substr($xml1, 0, strpos($xml1, "</Root>"))."</Root>";
  $doc1 = new DOMDocument("1.0", "utf-8");
  $doc1->loadXML($xml1);
  $datas = $doc1->getElementsByTagName("Data");
  foreach ($datas  as $data) {
    $errcode= $data->getAttribute("errcode");
    if ($errcode==0) {
      $_SESSION["user"]=$name;
      header("location:index.php");
    }
    else  showlogin("用户名或者密码错误！");
  }
}


function showdir($folder,$arg,$except=""){
	if($except==""){
		$arg1=substr($arg,0,strrpos($arg,"&"));
		$arg1=substr($arg1,0,strrpos($arg1,"&"));
		echo "<a href=../index.php?$arg1>返回 </a>&nbsp;&nbsp;&nbsp; $_GET[dir] &nbsp;&nbsp;&nbsp;<font color=red> JH-代表金华; HZ-代表杭州</font><hr>";
		$today = date("Ymd");
	}
	else{
		echo "<a href=../index.php>返回 </a>&nbsp;&nbsp;&nbsp; $_GET[dir] &nbsp;&nbsp;&nbsp;<font color=red> JH-代表金华; HZ-代表杭州</font><hr>";
	}
        $fp=opendir($folder);
        while(false!=$file=readdir($fp)) {
                if($file!='.' && $file!='..' && $file!=$except) {
                	$file="$file";
                	$arr_dir[]=$file;
		}
        }
        sort($arr_dir);
        if(is_array($arr_dir)) {
                while(list($key,$value)=each($arr_dir)) {
			if(ereg("file",$arg)){
				$string="<bold><font color=red size=+1>$value</font>";
				$string.="&nbsp;&nbsp;&nbsp;<a href=?$arg=$value&sort=bandwidth>流量统计</a>(BW)";
				$string.="&nbsp;&nbsp;&nbsp;<a href=?$arg=$value&sort=pv>页面统计</a>(PV)";
				$string.="&nbsp;&nbsp;&nbsp;<a href=?$arg=$value&sort=sum>合并统计</a>(SUM)</bold>";
			}
			else{
				if(ereg("^[0-9.*]",$value)){
					$string="<bold><a href=?$arg=$value>";
					if($value==$today) $string.="<font color=red size=+1>$value</font>";
					else $string.="<font color=navy>$value</font>";
				}
				else{
					$string="<bold>&nbsp;<a href=?host=$value>网络检测</a>";
					$string.="<bold>&nbsp;<a href=?load=$value>主机检测</a>";
					$string.="&nbsp;&nbsp;&nbsp;<a href=?black=$value>流量黑名单</a></bold>";
					$string.="&nbsp;&nbsp;&nbsp;<a href=?baduser=$value>账号黑名单</a></bold>";
					$string.="&nbsp;&nbsp;&nbsp;<a href=?blackip=$value>攻击IP名单</a></bold>";
					$string.="&nbsp;&nbsp;&nbsp;<a href=?$arg=$value>$value</a></bold>";
				}
				$string.="</a></bold>";
			}

			echo $string."<br>";
                }
        }
        closedir($fp);
}

function showfile($client,$file){
	print $client->do("monitor", $file);
}


if(isset($_GET[host]) && $_GET[host]!=""){
	print $client->do("monitor", $_GET[host]."@ping");
}


if(isset($_GET[load]) && $_GET[load]!=""){
	print $client->do("monitor", $_GET[load]."@uptime");
}

if(isset($_GET[black]) && $_GET[black]!=""){
	print $client->do("monitor", $_GET[black]."@blacklist");
}

if(isset($_GET[baduser]) && $_GET[baduser]!=""){
	print $client->do("monitor", $_GET[baduser]."@stoplist");
}

if(isset($_GET[blackip]) && $_GET[blackip]!=""){
	if(isset($_GET[bip]) && $_GET[bip]!=""){
			if(isset($_GET[opt]) && $_GET[opt]=="del"){
				print $client->do("monitor", $_GET[blackip]."#".$_GET[bip]."@delip");
			}
			else{
				print $client->do("monitor", $_GET[blackip]."#".$_GET[bip]."@blackip");
			}
	}
	else{
		echo "<form acton=index.php metho=post>";
		echo "<input type=text name=bip><input type=hidden name=blackip value=".$_GET[blackip]."><input type=submit value=查找>";
		echo "</form>";
	}
}

if(isset($_GET[dir]) && $_GET[dir]!=""){
	if(isset($_GET[date]) && $_GET[date]!=""){
		if(isset($_GET[file]) && $_GET[file]!=""){
			showfile($client,$_GET[dir]."/RESULT/".$_GET[date]."/".$_GET[file]."@".$_GET[sort]);
		}
		else{
			$dir3=$_GET[dir]."/RESULT/".$_GET[date];
			showdir($dir3,"dir=$_GET[dir]&date=$_GET[date]&file");
		}
	}
	else{
        	$dir2=$_GET[dir]."/RESULT/";
		showdir($dir2,"dir=$_GET[dir]&date");
	}
}
else{
        $dir1="/home/html/it";
	showdir($dir1,"dir","index.php");
}
echo "<hr><div align=right>Power by Linux,Copyright by Shaohy 53KF Inc.</div><br>";


function sendPOST($host,$url,$data)
{
  $fp = fsockopen($host, 80, $errno, $errstr, 60);
  if (!$fp)
  {
    echo "$errstr ($errno)<br />\n";
    return "";
  }
  fputs($fp, "POST $url HTTP/1.0\r\n");
  fputs($fp, "Host: $host\r\n");
  fputs($fp, "Content-type: application/x-www-form-urlencoded\r\n");
  fputs($fp, "Content-length: " . strlen($data) . "\r\n");
  fputs($fp, "User-Agent: MSIE\r\n");
  fputs($fp, "Connection: close\r\n\r\n");
  fputs($fp, $data);
  $buf='';
  while (!feof($fp))
  {
    $buf .= fgets($fp,128);
  }
  fclose($fp);

        return $buf;
}

function mysql_filter( $str, $charset="GB2312")
{
  return htmlentities(addcslashes($str,"\0..\32"),ENT_QUOTES,$charset);
}
?>
