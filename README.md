# macOS 内置词典内容拆解

最近女朋友在背单词，被我推荐了下 macOX 下自带的 New Oxford American Dictionary ，表示十分受用， 我就想着是否可以把词典内容，按需求取出，比如语源出处，或者派生词，这样更好去归纳记忆。

首先去查了 API ，通过官方的提供的文档来看只有 `DCSCopyTextDefinition` 可以或得到无标记的纯文本内容，通过文本解析来说定然没那么简单方便准确，所以找了下其他的方法。

## 调用 macOS 内置词典查询 
```swift
#! /usr/bin/env xcrun swift 

import Foundation
import CoreServices


func getDefinition(_ textString : String) -> String? {
    let range : CFRange = CFRangeMake(0, textString.characters.count)
    
    if let definition = DCSCopyTextDefinition(nil, textString, range) {
        return definition.takeRetainedValue() as String
    }
    return nil
}

func main() {
    if Process.arguments.count != 2{
        print("Usage: madicly [word]")
    } else {
        let word = Process.arguments[1]
        if let definition = getDefinition(word) {
            print(definition)
        } else {
            print("No definition found in Dictionary.")
        }
    }
}
main()
```

## 私有API
其实直觉上，直接解析词典包会比较容易，尝试再三后发现有诸多问题，在此略过，最终尝试找到可以通过私有 API `DCSCopyRecordsForSearchString` 来获得词典应用展示的 HTML 内容。 并没有找到如何用 Swift 调用私有 API 的方法，下面换了 objc。

```objective-c
#import <Foundation/Foundation.h>
NSArray *DCSCopyAvailableDictionaries();
NSArray *DCSCopyRecordsForSearchString(DCSDictionaryRef dictionary, CFStringRef string, void *, void *);
NSArray *DCSRecordCopyData(CFTypeRef record);
NSString *DCSDictionaryGetName(DCSDictionaryRef dictID);

NSString * const DictZh = @"牛津英汉汉英词典";
NSString * const DictEn = @"New Oxford American Dictionary";
NSString * const DictJa = @"ウィズダム英和辞典 / ウィズダム和英辞典";
NSString * const DictKo = @"뉴에이스 영한사전 / 뉴에이스 한영사전";

int main(int argc, char * argv[])
{
        @autoreleasepool {
        if(argc < 2)
        {
                printf("Usage: %s [word]\n", argv[0]);
                return -1;
        }
        NSString *dictname = DictEn;
        int c;
        while( (c = getopt(argc, argv, "zejk")) != -1) {
            switch(c) {
                case 'z':
                    dictname = DictZh;
                    break;
                case 'e':
                    dictname = DictEn;
                    break;
                case 'j':
                    dictname = DictJa;
                    break;
                case 'k':
                    dictname = DictKo;
                    break;
                case '?':
                    printf("Unknown flag: %c", optopt);
                    break;
            }
        }
        CFTypeRef dictionary = NULL;
        NSArray *dicts = DCSCopyAvailableDictionaries();
        for (NSObject *aDict in dicts) {
              NSString *aShortName =  DCSDictionaryGetName((DCSDictionaryRef)aDict);
              if ([aShortName isEqualToString:dictname])
                  dictionary = (DCSDictionaryRef)aDict;
        }
        NSString * word = [NSString stringWithCString: argv[2] encoding: NSUTF8StringEncoding];
        NSArray *records = DCSCopyRecordsForSearchString(dictionary, (CFStringRef)word, 0, 0);
        for (id record in records) {
            printf("%s", [(NSString*)DCSRecordCopyData(record) UTF8String]);
        }
        }
        return 0;
}
```

## 解析 HTML 

实际上去得到的内容还包含了 CSS 样式， 下面是去掉样式后的样子。

```HTML
<html>
   <body>
      <d:entry id="m_en_us1225918" d:title="benefactor" class="entry">
         <span class="hg"><span d:dhw="1" role="text" syllabified="ben·e·fac·tor" class="hw">benefactor<span class="gp tg_hw"> </span></span><span class="pr"> |<span d:pr="US_IPA" soundFile="benefactor#_us_2" media="online" geo="us" class="ph">ˈbɛnəˌfæktər</span>| </span><span class="gp tg_hg"> </span></span><span class="sg"><span class="se1"><span class="gp tg_se1">▶</span><span role="text" class="posg"><span d:ps="1" class="pos"><span class="gp tg_pos">noun</span></span><span class="gp tg_posg"> </span></span><span d:abs="1" id="m_en_us1225918.001" class="msDict t_core"><span role="text" class="df">a person who gives money or other help to a person or cause<span class="gp tg_df">.</span></span></span></span><span class="gp tg_sg"> </span></span>
         <span role="text" class="etym">
            <span class="gp ty_label tg_etym">ORIGIN </span><span class="dg"><span class="date">late Middle English</span></span>: from <span class="la">Latin</span>
            <html>
               <body>
                  <d:entry id="m_en_us1225918" d:title="benefactor" class="entry"><span class="hg"><span d:dhw="1" role="text" syllabified="ben·e·fac·tor" class="hw">benefactor<span class="gp tg_hw"> </span></span><span class="pr"> |<span d:pr="US_IPA" soundFile="benefactor#_us_2" media="online" geo="us" class="ph">ˈbɛnəˌfæktər</span>| </span><span class="gp tg_hg"> </span></span><span class="sg"><span class="se1"><span class="gp tg_se1">▶</span><span role="text" class="posg"><span d:ps="1" class="pos"><span class="gp tg_pos">noun</span></span><span class="gp tg_posg"> </span></span><span d:abs="1" id="m_en_us1225918.001" class="msDict t_core"><span role="text" class="df">a person who gives money or other help to a person or cause<span class="gp tg_df">.</span></span></span></span><span class="gp tg_sg"> </span></span><span role="text" class="etym"><span class="gp ty_label tg_etym">ORIGIN </span><span class="dg"><span class="date">late Middle English</span></span>: from <span class="la">Latin</span>, from <span class="ff"> bene facere  </span><span class="trans"><span class="gp tg_tr">‘</span>do good (to)<span class="gp tg_tr">’ </span></span><span class="xrg"> (see <span class="xr"><a href="x-dictionary:r:m_en_us1225916:com.apple.dictionary.NOAD">benefaction</a></span>) </span><span class="gp tg_etym">.</span></span></d:entry>
               </body>
            </html>
            from <span class="ff"> bene facere  </span><span class="trans"><span class="gp tg_tr">‘</span>do good (to)<span class="gp tg_tr">’ </span></span><span class="xrg"> (see <span class="xr"><a href="x-dictionary:r:m_en_us1225916:com.apple.dictionary.NOAD">benefaction</a></span>) </span><span class="gp tg_etym">.</span>
         </span>
      </d:entry>
   </body>
</html>
```
## Python 解析 

简易的用 BeautifulSoup 解析了下写了个类，封装了下单词诸如音标，解释，语源等信息。

```python
#! /usr/bin/env python
import sys
from bs4 import BeautifulSoup
import subprocess


class Mdict:
    def __init__(self, word):
        self.word = word
        p = subprocess.Popen(['bin/dicttool', '-e', word],
                             stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE)
        out, err = p.communicate()
        self._soup = BeautifulSoup(out, "lxml")
        p_zh = subprocess.Popen(['bin/dicttool', '-z', word],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE)
        out_zh, err_zh = p_zh.communicate()
        self._soup_zh = BeautifulSoup(out_zh, "lxml")

    @property
    def IPAs(self):
        return [item.text.strip() for item in self._soup.find("span", "hg").findAll("span", {"d:pr": "US_IPA"})]

    @property
    def etym(self):
        res = self._soup.find("span", "etym")
        return(res.text if res else None)

    @property
    def derivatives(self):
        return [item.find("span", "l").text.strip() for item in self._soup.findAll("span", "subEntry")]

    @property
    def roots(self):
        return [item.text.strip() for item in self._soup.findAll("span", "ff")]

    @property
    def origin(self):
        return [item.text.strip() for item in self._soup.find("span", "etym").findAll("span", "la")]

    @property
    def definitions_zh(self):
        return [item.find("span", "trans").text.strip() for item in self._soup_zh.findAll("span", "trg")]


def printword(w):
    print(w.word, " ")
    print("|{}|".format(','.join(w.IPAs)))

    for i, k in enumerate(w.definitions_zh):
        print(i+1, ".", k)
    print("\n{}\n".format(w.etym))

if __name__ == '__main__':
    word = sys.argv[1]
    q = Mdict(word)
    printword(q)
```

## 使用

在 IPython 实验一下效果如下

```python
In [1]: from mdict import Mdict

In [2]: Mdict('benefactor')
Out[2]: <mdict.mod.Mdict instance at 0x10b86fab8>

In [3]: word = Mdict('benefactor')

In [4]: word.definitions_zh
Out[4]:
[u'\u8d5e\u52a9\u4eba',
 u'\u4e0d\u77e5\u540d\u7684/\u533f\u540d\u7684\u6350\u52a9\u8005']

In [5]: word.etym
Out[5]: u'ORIGIN late Middle English: from Latin, from  bene facere  \u2018do good (to)\u2019  (see benefaction) .'

In [6]: word.IPAs
Out[6]: [u'\u02c8b\u025bn\u0259\u02ccf\xe6kt\u0259r']

In [7]: word.origin
Out[7]: [u'Latin']

```

## 后记

到此，大概能满足我用 Python 批量的取得单词中的某项内容的需求， 遂把经过写下来供以后有需要的人参考。
抛砖引玉，简易的代码在 Github ，如果有兴趣请点赞支持或者完善代码。


## 附录

* [Dictionary Services Reference](https://developer.apple.com/library/mac/documentation/UserExperience/Reference/DictionaryServicesRef/)
* [ronaldoussoren / pyobjc — Bitbucket](https://bitbucket.org/ronaldoussoren/pyobjc/)

