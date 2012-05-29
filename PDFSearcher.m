//
//  PDFSearcher.m
//  Reader
//
//  Created by ind558 on 03/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PDFSearcher.h"

@implementation PDFSearcher
@synthesize currentData;
-(id)init
{
    if(self = [super init])
    {
        table = CGPDFOperatorTableCreate();
        CGPDFOperatorTableSetCallback(table, "TJ", arrayCallback);
        CGPDFOperatorTableSetCallback(table, "Tj", stringCallback);
    }
    return self;
}

void arrayCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    PDFSearcher * searcher = (PDFSearcher *)userInfo;
    
    CGPDFArrayRef array;
    
    bool success = CGPDFScannerPopArray(inScanner, &array);
    
    for(size_t n = 0; n < CGPDFArrayGetCount(array); n += 2)
    {
        if(n >= CGPDFArrayGetCount(array))
            continue;
        
        CGPDFStringRef string;
        success = CGPDFArrayGetString(array, n, &string);
        if(success)
        {
            NSString *data = (NSString *)CGPDFStringCopyTextString(string);
            [searcher.currentData appendFormat:@"%@", data];
            [data release];
        }
    }
}

void stringCallback(CGPDFScannerRef inScanner, void *userInfo)
{
    PDFSearcher *searcher = (PDFSearcher *)userInfo;
    
    CGPDFStringRef string;
    
    bool success = CGPDFScannerPopString(inScanner, &string);
    
    if(success)
    {
        NSString *data = (NSString *)CGPDFStringCopyTextString(string);
        [searcher.currentData appendFormat:@" %@", data];
        [data release];
    }
}

-(BOOL)page:(CGPDFPageRef)inPage containsString:(NSString *)inSearchString;
{
    [self setCurrentData:[NSMutableString string]];
    CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(inPage);
    CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, table, self);
    bool ret = CGPDFScannerScan(scanner);
    CGPDFScannerRelease(scanner);
    CGPDFContentStreamRelease(contentStream);
    NSLog(@"%@",[currentData uppercaseString]);
    NSLog(@"%d",[[currentData uppercaseString] 
                 rangeOfString:[inSearchString uppercaseString]].location != NSNotFound);
    return ([[currentData uppercaseString] 
             rangeOfString:[inSearchString uppercaseString]].location != NSNotFound);
}
@end
