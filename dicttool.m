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
